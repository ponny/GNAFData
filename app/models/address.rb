class Address < ApplicationRecord
  belongs_to :locality
  has_one :state, through: :locality

  validates :address_detail_pid, presence: true, uniqueness: true
  validates :street_name, presence: true

  scope :by_street_name, ->(name) { where("LOWER(street_name) LIKE LOWER(?)", "%#{name}%") }
  scope :by_number, ->(number) { where(number_first: number) }
  scope :by_postcode, ->(postcode) { joins(:locality).where(localities: { postcode: postcode }) }
  scope :by_suburb, ->(suburb) { joins(:locality).where("LOWER(localities.locality_name) LIKE LOWER(?)", "%#{suburb}%") }
  scope :by_state, ->(state) { joins(:state).where("states.state_abbreviation = ?", state.upcase) }

  def full_address
    parts = []
    unit_parts = []
    
    # Unit/Flat information first
    if flat_number
      flat_part = []
      # Use flat_type if available, otherwise use flat_type_code with proper mapping, otherwise default to "Unit"
      if flat_type.present?
        flat_label = flat_type
      elsif flat_type_code.present?
        # Map all flat type codes to proper names
        flat_label = case flat_type_code.upcase
                    when 'ANT' then 'Antenna'
                    when 'APT' then 'Apartment'
                    when 'ATM' then 'ATM'
                    when 'BLCK' then 'Block'
                    when 'BLDG' then 'Building'
                    when 'BTSD' then 'Boatshed'
                    when 'CARP' then 'Carpark'
                    when 'CARS' then 'Carspace'
                    when 'CLUB' then 'Club'
                    when 'CTGE' then 'Cottage'
                    when 'DUPL' then 'Duplex'
                    when 'FCTY' then 'Factory'
                    when 'FLAT' then 'Flat'
                    when 'GRGE' then 'Garage'
                    when 'HALL' then 'Hall'
                    when 'HSE' then 'House'
                    when 'KSK' then 'Kiosk'
                    when 'LOFT' then 'Loft'
                    when 'LOT' then 'Lot'
                    when 'MBTH' then 'Marine Berth'
                    when 'MSNT' then 'Maisonette'
                    when 'OFFC' then 'Office'
                    when 'PTHS' then 'Penthouse'
                    when 'REAR' then 'Rear'
                    when 'ROOM' then 'Room'
                    when 'SE' then 'Suite'
                    when 'SEC' then 'Section'
                    when 'SHED' then 'Shed'
                    when 'SHOP' then 'Shop'
                    when 'SHRM' then 'Showroom'
                    when 'SIGN' then 'Sign'
                    when 'SITE' then 'Site'
                    when 'STLL' then 'Stall'
                    when 'STOR' then 'Store'
                    when 'STR' then 'Shop'
                    when 'STU' then 'Studio'
                    when 'SUBS' then 'Substation'
                    when 'TNCY' then 'Tenancy'
                    when 'TNHS' then 'Townhouse'
                    when 'TWR' then 'Tower'
                    when 'UNIT' then 'Unit'
                    when 'VLLA' then 'Villa'
                    when 'VLT' then 'Vault'
                    when 'WARD' then 'Ward'
                    when 'WHSE' then 'Warehouse'
                    when 'WKSH' then 'Workshop'
                    else flat_type_code.titleize
                    end
      else
        flat_label = "Unit"
      end
      flat_part << flat_label
      flat_part << "#{flat_number_prefix}#{flat_number}#{flat_number_suffix}"
      unit_parts << flat_part.join(" ")
    end
    
    # Level information
    if level_number
      level_part = []
      # Use level_type if available, otherwise map level_type_code, otherwise default to "Level"
      if level_type.present?
        level_label = level_type
      elsif level_type_code.present?
        # Map all level type codes to proper names
        level_label = case level_type_code.upcase
                     when 'B' then 'Basement'
                     when 'FL' then 'Floor'
                     when 'L' then 'Level'
                     when 'LB' then 'Lower Basement'
                     when 'LG' then 'Lower Ground'
                     when 'M' then 'Mezzanine'
                     when 'P' then 'Platform'
                     when 'RT' then 'Rooftop'
                     when 'UG' then 'Upper Ground'
                     else level_type_code.titleize
                     end
      else
        level_label = "Level"
      end
      level_part << level_label
      level_part << "#{level_number_prefix}#{level_number}#{level_number_suffix}"
      unit_parts << level_part.join(" ")
    end
    
    # Street number range
    street_number = nil
    if number_first
      street_number = "#{number_first}#{number_suffix}"
      if number_last && number_last != number_first
        street_number += "-#{number_last}#{number_last_suffix}"
      end
    end
    
    # Combine unit info with street number using slash separator
    if unit_parts.any? && street_number
      parts << "#{unit_parts.join(" ")}/#{street_number}"
    elsif street_number
      parts << street_number
    end
    
    # Street name and type
    parts << street_name
    parts << street_type_name if street_type_name.present?
    
    # Location
    parts << locality.locality_name
    parts << locality.state.state_abbreviation
    parts << postcode
    
    parts.compact.reject(&:blank?).join(" ")
  end

  def self.search(query)
    return all if query.blank?
    
    # Split query into components for flexible searching
    terms = query.split(/\s+/)
    
    scope = all
    terms.each do |term|
      scope = scope.where(
        "LOWER(street_name) LIKE LOWER(?) OR 
         LOWER(localities.locality_name) LIKE LOWER(?) OR 
         localities.postcode = ? OR
         CAST(number_first AS TEXT) LIKE ?",
        "%#{term}%", "%#{term}%", term, "#{term}%"
      ).joins(:locality)
    end
    
    scope.includes(:locality, state: :localities)
  end
end

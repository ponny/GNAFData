class Address < ApplicationRecord
  belongs_to :locality
  belongs_to :street_type, optional: true
  has_one :state, through: :locality

  validates :address_detail_pid, presence: true, uniqueness: true
  validates :street_name, presence: true

  scope :by_street_name, ->(name) { where("street_name LIKE ? COLLATE NOCASE", "%#{name}%") }
  scope :by_number, ->(number) { where(number_first: number) }
  scope :by_postcode, ->(postcode) { joins(:locality).where(localities: { postcode: postcode }) }
  scope :by_suburb, ->(suburb) { joins(:locality).where("localities.locality_name LIKE ? COLLATE NOCASE", "%#{suburb}%") }
  scope :by_state, ->(state) { joins(:state).where("states.state_abbreviation = ?", state.upcase) }

  def full_address
    parts = []
    parts << "#{number_first}#{number_suffix}" if number_first
    parts << "#{number_last}#{number_last_suffix}" if number_last && number_last != number_first
    parts << street_name
    parts << street_type&.street_type_name
    parts << locality.locality_name
    parts << locality.state.state_abbreviation
    parts << locality.postcode
    parts.compact.join(" ")
  end

  def self.search(query)
    return all if query.blank?
    
    # Split query into components for flexible searching
    terms = query.split(/\s+/)
    
    scope = all
    terms.each do |term|
      scope = scope.where(
        "street_name LIKE ? COLLATE NOCASE OR 
         localities.locality_name LIKE ? COLLATE NOCASE OR 
         localities.postcode = ? OR
         CAST(number_first AS TEXT) LIKE ?",
        "%#{term}%", "%#{term}%", term, "#{term}%"
      ).joins(:locality)
    end
    
    scope.includes(:locality, :street_type, state: :localities)
  end
end

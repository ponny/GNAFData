class LocalitiesController < ApplicationController
  def index
    # Use a subquery to get address counts
    address_counts = Address.group(:locality_id).count
    
    @localities = Locality.includes(:state)
                          .joins(:state)
                          .order("states.state_name, localities.locality_name")
    
    # Add address_count as a virtual attribute
    @localities = @localities.map do |locality|
      locality.define_singleton_method(:address_count) do
        address_counts[self.id] || 0
      end
      locality.define_singleton_method(:state_name) do
        self.state.state_name
      end
      locality
    end
    
    @total_localities = @localities.length
    @total_addresses = Address.count
  end

  def show
    @locality = Locality.find(params[:id])
    @addresses = @locality.addresses.order(:street_name, :number_first)
    @address_list = @addresses.map(&:full_address).join("\n")
  end

  def download_csv
    @locality = Locality.find(params[:id])
    @addresses = @locality.addresses.includes(:locality)
    
    respond_to do |format|
      format.csv do
        csv_data = generate_csv(@addresses)
        send_data csv_data, 
                  filename: "#{@locality.locality_name.parameterize}-addresses.csv",
                  type: 'text/csv'
      end
    end
  end

  private

  def generate_csv(addresses)
    CSV.generate(headers: true) do |csv|
      csv << [
        'Full Address',
        'Address Detail PID',
        'Number First',
        'Number Suffix',
        'Number Last', 
        'Number Last Suffix',
        'Street Name',
        'Street Type',
        'Level Type Code',
        'Level Number',
        'Flat Type Code',
        'Flat Number',
        'Building Name',
        'Locality Name',
        'State',
        'Postcode',
        'Confidence',
        'Date Created'
      ]
      
      addresses.find_each do |address|
        csv << [
          address.full_address,
          address.address_detail_pid,
          address.number_first,
          address.number_suffix,
          address.number_last,
          address.number_last_suffix,
          address.street_name,
          address.street_type_name,
          address.level_type_code,
          address.level_number,
          address.flat_type_code,
          address.flat_number,
          address.building_name,
          address.locality.locality_name,
          address.locality.state.state_name,
          address.locality.postcode,
          address.confidence,
          address.date_created&.strftime('%Y-%m-%d')
        ]
      end
    end
  end
end

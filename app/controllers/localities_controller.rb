class LocalitiesController < ApplicationController
  def index
    @localities = Locality.includes(:state)
                          .joins("LEFT JOIN addresses ON addresses.locality_id = localities.id")
                          .group("localities.id, states.state_name")
                          .select("localities.*, states.state_name, COUNT(addresses.id) as address_count")
                          .order("states.state_name, localities.locality_name")
    
    @total_localities = @localities.length
    @total_addresses = Address.count
  end

  def download_csv
    @locality = Locality.find(params[:id])
    @addresses = @locality.addresses.includes(:locality, :street_type)
    
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
          address.address_detail_pid,
          address.number_first,
          address.number_suffix,
          address.number_last,
          address.number_last_suffix,
          address.street_name,
          address.street_type&.street_type_name,
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

class AddressesController < ApplicationController
  def index
    @addresses = Address.includes(:locality, state: :localities)
    
    if params[:search].present?
      @addresses = @addresses.search(params[:search])
    end
    
    if params[:state].present?
      @addresses = @addresses.by_state(params[:state])
    end
    
    if params[:postcode].present?
      @addresses = @addresses.by_postcode(params[:postcode])
    end
    
    @addresses = @addresses.limit(100) # Limit results for performance
    @total_count = Address.count
    @search_count = @addresses.count
  end

  def show
    @address = Address.includes(:locality, state: :localities)
                    .find(params[:id])
  end

  def stats
    @stats = {
      total_addresses: Address.count,
      total_localities: Locality.count,
      total_states: State.count,
      unique_street_types: Address.distinct.count(:street_type_name),
      addresses_by_state: Address.joins(locality: :state)
                                .group('states.state_abbreviation')
                                .count
                                .sort_by { |_, count| -count },
      top_postcodes: Address.joins(:locality)
                           .group('localities.postcode')
                           .count
                           .sort_by { |_, count| -count }
                           .first(10)
    }
  end
end

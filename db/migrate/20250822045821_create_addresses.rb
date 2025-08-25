class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.string :address_detail_pid, null: false, index: { unique: true }
      t.string :street_locality_pid
      t.references :locality, null: false, foreign_key: true
      t.references :street_type, null: true, foreign_key: true
      
      # Address number components
      t.integer :number_first
      t.string :number_suffix, limit: 15
      t.integer :number_last
      t.string :number_last_suffix, limit: 15
      
      # Street information
      t.string :street_name, null: false
      t.string :street_class_code
      t.string :street_class_type
      
      # Unit/Level information
      t.string :level_type_code
      t.string :level_type
      t.string :level_number_prefix
      t.integer :level_number
      t.string :level_number_suffix
      
      # Flat/Unit information
      t.string :flat_type_code
      t.string :flat_type
      t.string :flat_number_prefix
      t.integer :flat_number
      t.string :flat_number_suffix
      
      # Building information
      t.string :building_name
      t.string :lot_number_prefix
      t.string :lot_number
      t.string :lot_number_suffix
      
      # Geographic coordinates
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      
      # Confidence and legal status
      t.integer :geocode_reliability_code
      t.string :confidence
      t.string :legal_parcel_id
      
      # Dates
      t.date :date_created
      t.date :date_last_modified
      t.date :date_retired

      t.timestamps
    end

    add_index :addresses, :street_name
    add_index :addresses, :number_first
    add_index :addresses, [:latitude, :longitude]
    add_index :addresses, :building_name
  end
end

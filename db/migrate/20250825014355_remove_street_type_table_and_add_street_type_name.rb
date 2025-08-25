class RemoveStreetTypeTableAndAddStreetTypeName < ActiveRecord::Migration[8.0]
  def change
    # Add street_type_name column to addresses
    add_column :addresses, :street_type_name, :string
    add_index :addresses, :street_type_name
    
    # Remove the foreign key constraint and street_type_id column
    remove_foreign_key :addresses, :street_types
    remove_column :addresses, :street_type_id, :bigint
    
    # Drop the street_types table
    drop_table :street_types do |t|
      t.string :street_type_code, null: false
      t.string :street_type_name, null: false
      t.string :street_type_description
      t.date :date_created
      t.date :date_retired
      t.timestamps
    end
  end
end

class CreateStreetTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :street_types do |t|
      t.string :street_type_code, null: false, index: { unique: true }
      t.string :street_type_name, null: false
      t.string :street_type_description

      t.timestamps
    end
  end
end

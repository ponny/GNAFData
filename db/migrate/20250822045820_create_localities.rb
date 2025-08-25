class CreateLocalities < ActiveRecord::Migration[8.0]
  def change
    create_table :localities do |t|
      t.string :locality_pid, null: false, index: { unique: true }
      t.string :locality_name, null: false
      t.string :locality_class_code
      t.string :locality_class_name
      t.references :state, null: false, foreign_key: true
      t.string :postcode
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.date :date_created
      t.date :date_retired

      t.timestamps
    end

    add_index :localities, :postcode
    add_index :localities, :locality_name
    add_index :localities, [:latitude, :longitude]
  end
end

class CreateStates < ActiveRecord::Migration[8.0]
  def change
    create_table :states do |t|
      t.string :state_pid, null: false, index: { unique: true }
      t.string :state_name, null: false
      t.string :state_abbreviation, null: false, limit: 3
      t.date :date_created
      t.date :date_retired

      t.timestamps
    end

    add_index :states, :state_abbreviation
  end
end

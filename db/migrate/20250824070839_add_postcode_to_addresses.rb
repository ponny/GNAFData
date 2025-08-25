class AddPostcodeToAddresses < ActiveRecord::Migration[8.0]
  def change
    add_column :addresses, :postcode, :string
    add_index :addresses, :postcode
  end
end

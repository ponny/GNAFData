class StreetType < ApplicationRecord
  has_many :addresses, dependent: :destroy

  validates :street_type_code, presence: true, uniqueness: true
  validates :street_type_name, presence: true
end

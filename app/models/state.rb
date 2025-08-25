class State < ApplicationRecord
  has_many :localities, dependent: :destroy
  has_many :addresses, through: :localities

  validates :state_pid, presence: true, uniqueness: true
  validates :state_name, presence: true
  validates :state_abbreviation, presence: true
end

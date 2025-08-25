class Locality < ApplicationRecord
  belongs_to :state
  has_many :addresses, dependent: :destroy

  validates :locality_pid, presence: true, uniqueness: true
  validates :locality_name, presence: true
  # Note: Some localities may not have a postcode in GNAF data

  scope :by_postcode, ->(postcode) { where(postcode: postcode) }
  scope :by_state, ->(state_abbreviation) { joins(:state).where(states: { state_abbreviation: state_abbreviation }) }
end

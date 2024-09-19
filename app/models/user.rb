class User < ApplicationRecord
  belongs_to :account

  has_many :sessions, dependent: :destroy
  has_secure_password validations: false

  has_many :accesses, dependent: :destroy
  has_many :projects, through: :accesses
  has_many :bubbles, through: :projects

  has_many :assignments
  has_many :assigned_bubbles, through: :assignments, source: :bubble

  validates_presence_of :email_address
  normalizes :email_address, with: ->(value) { value.strip.downcase }

  scope :active, -> { where(active: true) }

  def initials
    name.scan(/\b\w/).join
  end

  def deactivate
    transaction do
      sessions.destroy_all
      accesses.destroy_all
      update! active: false, email_address: deactived_email_address
    end
  end

  private
    def deactived_email_address
      email_address.sub(/@/, "-deactivated-#{SecureRandom.uuid}@")
    end
end

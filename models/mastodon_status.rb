# In your minimal models/status.rb:
class MastodonStatus < ApplicationRecord
  belongs_to :mastodon_account
  has_one :mastodon_status_stat, inverse_of: :mastodon_status, dependent: :destroy
  
  # Add this to satisfy the recount logic
  has_many :replies, class_name: 'MastodonStatus', foreign_key: 'in_reply_to_id'
  has_many :reblogs, class_name: 'MastodonStatus', foreign_key: 'reblog_of_id'
  has_many :favourites, class_name: 'Favourite', dependent: :destroy
  has_many :quotes, class_name: 'MastodonStatus', foreign_key: 'quoted_status_id'

  def self.not_direct_visibility
    where.not(visibility: :direct)
  end

  def self.accepted
    all
  end
end
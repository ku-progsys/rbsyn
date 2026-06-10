class Favourite < ApplicationRecord
  # Explicitly point to your custom account and status models
  belongs_to :mastodon_account, class_name: 'MastodonAccount', foreign_key: 'mastodon_account_id'
  belongs_to :mastodon_status,  class_name: 'MastodonStatus',  foreign_key: 'mastodon_status_id'
end
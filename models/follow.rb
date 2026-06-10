class Follow < ApplicationRecord
  belongs_to :mastodon_account, class_name: 'MastodonAccount'
  belongs_to :target_account, class_name: 'MastodonAccount'
end
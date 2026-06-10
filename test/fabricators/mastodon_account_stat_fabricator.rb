# frozen_string_literal: true

Fabricator(:mastodon_account_stat) do
  mastodon_account { Fabricate.build(:mastodon_account) }
  statuses_count  '123'
  following_count '456'
  followers_count '789'
end
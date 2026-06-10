require "securerandom"

Fabricator(:mastodon_status) do
  mastodon_account { Fabricate.build(:mastodon_account) }
  text 'Lorem ipsum dolor sit amet'

  after_build do |status|
    status.uri = SecureRandom.hex(16) if !status.mastodon_account.local? && status.uri.nil?
  end
end
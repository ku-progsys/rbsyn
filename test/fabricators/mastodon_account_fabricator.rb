# frozen_string_literal: true

keypair     = OpenSSL::PKey::RSA.new(2048)
public_key  = keypair.public_key.to_pem
private_key = keypair.to_pem

Fabricator(:mastodon_account) do
  username            { sequence(:username) { |i| "user_#{i}" } }
  public_key          { public_key }
  private_key         { private_key }
  uri                 { |attrs| attrs[:domain].nil? ? '' : "https://#{attrs[:domain]}/users/#{attrs[:username]}" }
  discoverable        true
end

Fabricator(:remote_mastadon_account, from: :mastodon_account) do
  domain 'example.com'
end
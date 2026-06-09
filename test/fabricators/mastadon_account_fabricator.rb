
Fabricator(:account) do
  username { sequence(:username) { |i| "user#{i}" } }
end


Fabricator(:appeal) do
  strike(fabricator: :account_warning)
  account { |attrs| attrs[:strike].target_account }
  text { Faker::Lorem.paragraph }
end

Fabricator(:account_warning) do
  account { Fabricate.build(:account) }
  target_account(fabricator: :account)
  text { Faker::Lorem.paragraph }
  action 'suspend'
end

Fabricator(:account_warning_preset) do
  text { Faker::Lorem.paragraph }
end
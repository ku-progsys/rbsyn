
Fabricator(:account) do
  username { sequence(:username) { |i| "user#{i}" } }
end

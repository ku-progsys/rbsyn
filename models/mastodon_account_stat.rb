

class MastodonAccountStat < ApplicationRecord
  self.locking_column = nil

  belongs_to :mastodon_account, inverse_of: :mastodon_account_stat

  scope :by_recent_status, -> { order(arel_table[:last_status_at].desc.nulls_last) }
  scope :without_recent_activity, -> { where(last_status_at: [nil, ...1.month.ago]) }

  update_index('mastodon_accounts', :mastadon_account)

  def following_count
    [attributes['following_count'], 0].max
  end

  def followers_count
    [attributes['followers_count'], 0].max
  end

  def statuses_count
    [attributes['statuses_count'], 0].max
  end
end
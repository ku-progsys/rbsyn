# frozen_string_literal: true

require_relative 'base'
# require 'active_support/cache'
# Rails.cache = ActiveSupport::Cache::MemoryStore.new

module Mastodon::CLI
  class Cache < Base
    desc 'clear', 'Clear out the cache storage'
    def clear
      Rails.cache.clear
      say('OK', :green)
    end

    option :concurrency, type: :numeric, default: 5, aliases: [:c]
    option :verbose, type: :boolean, aliases: [:v]
    desc 'recount TYPE', 'Update hard-cached counters'
    long_desc <<~LONG_DESC
      Update hard-cached counters of TYPE by counting referenced
      records from scratch. TYPE can be "accounts" or "statuses".

      It may take a very long time to finish, depending on the
      size of the database.
    LONG_DESC
    def recount(type)
      # require pry 
      # require pry-byebug
      # binding.pry
      # puts "HERE: #{type}"
      # binding.pry
      case type
      
      when 'mastodon_accounts'
        #binding.pry
        processed, = parallelize_with_progress(accounts_with_stats) do |account|
          recount_account_stats(account)
        end
      when 'mastodon_statuses'
        processed, = parallelize_with_progress(statuses_with_stats) do |status|
          recount_status_stats(status)
        end
      else

        fail_with_message "Unknown type: #{type}"
      end

      say
      say("OK, recounted #{processed} records", :green)
    end

    private

    def accounts_with_stats
      MastodonAccount.local.includes(:mastodon_account_stat)
    end

    def statuses_with_stats
      MastodonStatus.includes(:mastodon_status_stat)
    end

    def recount_account_stats(account)
      account.mastodon_account_stat.tap do |account_stat|
        account_stat.following_count = account.active_relationships.count
        account_stat.followers_count = account.passive_relationships.count
        account_stat.statuses_count  = account.mastodon_statuses.not_direct_visibility.count

        account_stat.save if account_stat.changed?
      end
    end

    def recount_status_stats(status)
      status.mastodon_status_stat.tap do |status_stat|
        status_stat.replies_count    = status.replies.not_direct_visibility.count
        status_stat.reblogs_count    = status.reblogs.count
        status_stat.favourites_count = status.favourites.count
        status_stat.quotes_count     = status.quotes.accepted.count

        status_stat.save if status_stat.changed?
      end
    end
  end
end
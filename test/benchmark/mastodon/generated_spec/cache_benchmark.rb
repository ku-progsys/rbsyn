require 'test_helper'
require_relative "../dependencies/cli/cache.rb"
describe "Mastodon::CLI::Cache" do 
  it "#recount" do 
    
    #original definition: 
    #
    # def recount(type)
    #   case type
    #   when 'mastodon_accounts'
    #     processed, = parallelize_with_progress(accounts_with_stats) do |account|
    #       recount_account_stats(account)
    #     end
    #   when 'mastodon_statuses'
    #     processed, = parallelize_with_progress(statuses_with_stats) do |status|
    #       recount_status_stats(status)
    #     end
    #   else

    #     fail_with_message "Unknown type: #{type}"
    #   end

    #   say
    #   say("OK, recounted #{processed} records", :green)
    # end
    
    load_typedefs :stdlib, :active_record
    #DEFS from cache
    # Mastodon::CLI::Cache
    # Recount is the only method taking the receiver explicitly
    # RDL.type Mastodon::CLI::Cache, :recount, "(Mastodon::CLI::Cache, String) -> %bot", write: [MastodonAccountStat, MastodonStatusStat], read: [MastodonAccount, MastodonStatus]

    # Other methods are standard instance methods (no explicit receiver argument)
    RDL.type Mastodon::CLI::Cache, :recount_mastodon_accounts, "() -> %bot", write: [MastodonAccountStat], read: [MastodonAccount]
    RDL.type Mastodon::CLI::Cache, :recount_status_stats, "() -> %bot", write: [MastodonStatusStat], read: [MastodonStatus]

    # Mastodon::CLI::Base
    RDL.type Mastodon::CLI::Base, :fail_with_message, "(String) -> %bot", write: []

    # Mastodon::CLI::ProgressHelper
    RDL.type Mastodon::CLI::ProgressHelper, :parallelize_with_progress, "(Enumerable, Proc) -> %bot", read: []



    define :recount, "(Mastadon::CLI::Cache, String) -> %bot", [], consts: true  do


      spec "re-calculates mastodon_account records in the cache" do
        setup {
          @stat = Fabricate(:mastodon_account_stat)
          @stat.update(statuses_count: 123)
          @cli = Mastodon::CLI::Cache.new
          recount(@cli, 'mastodon_accounts')
        }
        post { |result|
          assert { @stat.reload.statuses_count == 0 }
        }
      end

      spec "re-calculates mastodon_status records in the cache" do
        setup {
          @stat = Fabricate(:mastodon_status_stat)
          @stat.update(replies_count: 123)
          @cli = Mastodon::CLI::Cache.new
          recount(@cli, 'mastodon_statuses')
        }
        post { |result|
          assert { @stat.reload.replies_count == 0 }
        }
      end

      spec "exits with an error for unknown types" do
        setup {
          @cli = Mastodon::CLI::Cache.new
        }
        post { |result|
          assert {
            begin
              recount(@cli, 'other-type')
              false
            rescue Thor::Error
              true
            end
          }
        }
      end
      generate_program
    end
  end
end
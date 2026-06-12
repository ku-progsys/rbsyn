require 'test_helper'
require_relative "../dependencies/cli/cache.rb"
describe "Mastodon::CLI::Cache" do 
  it "#recount" do 
    
    
    load_typedefs :stdlib, :active_record

    RDL.type_params Array, [:t], :all?
    #Right side methods
    RDL.type :"MastodonAccount", :active_relationships, "() -> Follow::ActiveRecord_Associations_CollectionProxy"
    RDL.type :"MastodonAccount", :passive_relationships, "() -> Follow::ActiveRecord_Associations_CollectionProxy"
    RDL.type :"MastodonAccount", :mastodon_statuses, "() -> MastodonStatus::ActiveRecord_Associations_CollectionProxy"
    RDL.type :'MastodonStatus::ActiveRecord_Associations_CollectionProxy', :not_direct_visibility, "() -> MastodonStatus::ActiveRecord_AssociationRelation"

    RDL.type :"MastodonAccount", :mastodon_account_stat, "() -> MastodonAccountStat"
    RDL.type :"MastodonAccountStat", :following_count=,  "(Integer) -> Integer", write: ["MastodonAccountStat.following_count"]
    RDL.type :"MastodonAccountStat", :followers_count=,  "(Integer) -> Integer", write: ["MastodonAccountStat.followers_count"]
    RDL.type :"MastodonAccountStat", :statuses_count=,  "(Integer) -> Integer", write: ["MastodonAccountStat.statuses_count"]

    RDL.type :"MastodonStatus::ActiveRecord_AssociationRelation", :count, "() -> Integer"
    RDL.type :"Follow::ActiveRecord_Associations_CollectionProxy", :count, "() -> Integer"

    RDL.type :MastodonAccountStat, :save, "() -> %bool", write: ["MastodonAccountStat"]

    define :recount_account_stats, "(MastodonAccount) -> %bool", [], consts: true , moi: [] do


      spec "re-calculates mastodon_account records in the cache" do
        setup {
          @stat = Fabricate(:mastodon_account_stat)
          @stat.update(statuses_count: 123)
          @cli = Mastodon::CLI::Cache.new
          recount_account_stats(@cli.accounts_with_stats[0])

        }
        post { |result|
          assert { @stat.reload.statuses_count == 0 }
        }
      end

      generate_program
    end
  end
end
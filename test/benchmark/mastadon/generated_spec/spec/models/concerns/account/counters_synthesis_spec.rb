require "test_helper"
require_relative "../../../rails_helper"

describe "Account" do
  it "account#update_count!" do
    load_typedefs :stdlib, :active_record

    class Account
      def helper_updated_account_stat(key, value, status_created_at: nil)
  
          updated_account_stat(key, value.to_i, status_created_at: nil)
      end


    end

    # class Array
    #     def all_dead?
    #         all? { |x| x.alive? }
    #     end
    # end

    # RDL.type Array, :all_dead?, '() -> %bool', wrap: false

    RDL.type Account, "account_stat", "() -> AccountStat", wrap: false

    RDL.type Account, "association", "(Symbol) -> AssociationMock", wrap: false

    RDL.type Account, "helper_updated_account_stat", "(Symbol, Integer) -> Array", write: ["AccountStat"], wrap: false

    RDL.type Account, "account_stat", "() -> AccountStat", wrap: false

    RDL.type AccountStat, :reload, '() -> AccountStat', write: ["Account"], wrap: false

    RDL.type Account, :followers_count, '() -> Integer', wrap: false

    RDL.type Integer, :!=, '(Integer) -> %bool', wrap: false

    RDL.type Integer, :==, '(Integer) -> %bool', wrap: false

    #RDL.type Integer, :to_i, '() -> Integer', wrap: false
    #binding.pry

    define :update_count!, "(Account, Symbol, Integer, status_created_at: ?Time) -> %any", [:account_stat], prog_size: 50 do


      spec "increments the count in multi-threaded environment" do
        setup {
          @account = Fabricate(:account)
          increment_by = 15
          x = multi_threaded_execution(increment_by) do
            update_count!(@account, :statuses_count, 1, nil)
          end

          x.all? { |t| !t.alive? }
        }
        post { |result|
          assert { @account.statuses_count == 15 }
        }
      end



      spec "increments the count" do
        setup {
          @account = Fabricate(:account)
          update_count!(@account, :followers_count, 1 ,nil)
        }
        post { |result|
          assert { @account.followers_count == 1 }
        }
      end



      # spec "updates last_status_at when discovering a new post" do
      #   setup {
      #     @account = Fabricate(:account)
      #     @status_created_at = Time.now.utc
      #     @old_last_status_at = @account.last_status_at
      #     update_count!(@account, :statuses_count, 1, status_created_at: @status_created_at)
      #   }
      #   post { |result|
      #     assert { @account.reload.last_status_at != @old_last_status_at }
      #   }
      # end

      # spec "does not update last_status_at when discovering an older post" do
      #   setup {
      #     @account = Fabricate(:account)
      #     @account_stat = Fabricate(:account_stat, account: @account, last_status_at: 1.day.ago.utc, statuses_count: 10)
      #     @old_last_status_at = @account_stat.last_status_at
      #     @status_created_at = 2.days.ago.utc
      #     update_count!(@account, :statuses_count, 1, status_created_at: @status_created_at)
      #   }
      #   post { |result|
      #     assert { @account_stat.reload.statuses_count == 11 }
      #     assert { @account_stat.reload.last_status_at == @old_last_status_at }
      #   }
      # end

      # spec "decrements the count" do
      #   setup {
      #     @account = Fabricate(:account)
      #     @account.followers_count = 15
      #     @account.save!
      #     update_count!(@account, :followers_count, -1)
      #   }
      #   post { |result|
      #     assert { @account.followers_count == 14 }
      #   }
      # end

      # spec "preserves last_status_at when decrementing statuses_count" do
      #   setup {
      #     @account = Fabricate(:account)
      #     @account_stat = Fabricate(:account_stat, account: @account, last_status_at: 3.days.ago, statuses_count: 10)
      #     @old_last_status_at = @account_stat.last_status_at
      #     update_count!(@account, :statuses_count, -1)
      #   }
      #   post { |result|
      #     assert { @account_stat.reload.statuses_count == 9 }
      #     assert { @account_stat.reload.last_status_at == @old_last_status_at }
      #   }
      # end

      generate_program
    end
  end
end

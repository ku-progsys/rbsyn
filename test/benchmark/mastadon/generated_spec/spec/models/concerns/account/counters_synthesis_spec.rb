require "test_helper"
require_relative "../../../rails_helper"

describe "Account" do
  it "account#increment_count!" do
    load_typedefs :stdlib, :active_record

    RDL.type Account, :followers_count, '() -> Integer', wrap: false
    RDL.type Account, :followers_count=, '(Integer) -> Integer', wrap: false
    RDL.type Account, :statuses_count, '() -> Integer', wrap: false
    RDL.type Account, :statuses_count=, '(Integer) -> Integer', wrap: false
    RDL.type Account, :last_status_at, '() -> Time', wrap: false
    RDL.type Account, :save!, '() -> %bool', wrap: false
    RDL.type Account, :reload, '() -> Account', wrap: false

    RDL.type AccountStat, :statuses_count, '() -> Integer', wrap: false
    RDL.type AccountStat, :last_status_at, '() -> Time', wrap: false
    RDL.type AccountStat, :reload, '() -> AccountStat', wrap: false

    RDL.type Time, 'self.now', '() -> Time', wrap: false
    RDL.type Time, :utc, '() -> Time', wrap: false
    RDL.type Time, :!=, '(Time) -> %bool', wrap: false
    RDL.type Time, :==, '(Time) -> %bool', wrap: false

    RDL.type Integer, :!=, '(Integer) -> %bool', wrap: false
    RDL.type Integer, :==, '(Integer) -> %bool', wrap: false

    define :increment_count!, "(Account, Symbol, ?{status_created_at: Time}) -> %any", [Account], prog_size: 50 do
      spec "increments the count" do
        setup {
          @account = Fabricate(:account)
          increment_count!(@account, :followers_count)
        }
        post { |result|
          assert { @account.followers_count == 1 }
        }
      end

      spec "updates last_status_at when discovering a new post" do
        setup {
          @account = Fabricate(:account)
          @status_created_at = Time.now.utc
          @old_last_status_at = @account.last_status_at
          increment_count!(@account, :statuses_count, status_created_at: @status_created_at)
        }
        post { |result|
          assert { @account.reload.last_status_at != @old_last_status_at }
        }
      end

      spec "does not update last_status_at when discovering an older post" do
        setup {
          @account = Fabricate(:account)
          @account_stat = Fabricate(:account_stat, account: @account, last_status_at: 1.day.ago.utc, statuses_count: 10)
          @old_last_status_at = @account_stat.last_status_at
          @status_created_at = 2.days.ago.utc
          increment_count!(@account, :statuses_count, status_created_at: @status_created_at)
        }
        post { |result|
          assert { @account_stat.reload.statuses_count == 11 }
          assert { @account_stat.reload.last_status_at == @old_last_status_at }
        }
      end

      generate_program
    end
  end

  it "account#decrement_count!" do
    load_typedefs :stdlib, :active_record

    RDL.type Account, :followers_count, '() -> Integer', wrap: false
    RDL.type Account, :followers_count=, '(Integer) -> Integer', wrap: false
    RDL.type Account, :statuses_count, '() -> Integer', wrap: false
    RDL.type Account, :save!, '() -> %bool', wrap: false
    RDL.type Account, :reload, '() -> Account', wrap: false

    RDL.type AccountStat, :statuses_count, '() -> Integer', wrap: false
    RDL.type AccountStat, :last_status_at, '() -> Time', wrap: false
    RDL.type AccountStat, :reload, '() -> AccountStat', wrap: false

    RDL.type Integer, :!=, '(Integer) -> %bool', wrap: false
    RDL.type Integer, :==, '(Integer) -> %bool', wrap: false

    define :decrement_count!, "(Account, Symbol) -> %any", [Account], prog_size: 50 do
      spec "decrements the count" do
        setup {
          @account = Fabricate(:account)
          @account.followers_count = 15
          @account.save!
          decrement_count!(@account, :followers_count)
        }
        post { |result|
          assert { @account.followers_count == 14 }
        }
      end

      spec "preserves last_status_at when decrementing statuses_count" do
        setup {
          @account = Fabricate(:account)
          @account_stat = Fabricate(:account_stat, account: @account, last_status_at: 3.days.ago, statuses_count: 10)
          @old_last_status_at = @account_stat.last_status_at
          decrement_count!(@account, :statuses_count)
        }
        post { |result|
          assert { @account_stat.reload.statuses_count == 9 }
          assert { @account_stat.reload.last_status_at == @old_last_status_at }
        }
      end

      generate_program
    end
  end
end

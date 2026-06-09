# frozen_string_literal: true
#require 'rspec'

require 'active_support/all'

# Mock Arel
# module Arel
#   def self.sql(str)
#     str
#   end
# end


# Multi-threaded execution mock
def multi_threaded_execution(thread_count)
  threads = thread_count.times.map do
    Thread.new do
      yield
    end
  end
  threads.each(&:join)
end

# Mock Database
$db = { account_stats: {} }
$next_id = 1

class AccountStat
  attr_accessor :id, :account_id, :statuses_count, :following_count, :followers_count, :last_status_at

  def initialize(attrs = {})
    @id = attrs[:id] || attrs['id']
    @account_id = attrs[:account_id]
    @statuses_count = attrs[:statuses_count] || 0
    @following_count = attrs[:following_count] || 0
    @followers_count = attrs[:followers_count] || 0
    @last_status_at = attrs[:last_status_at]
  end

  def new_record?
    @id.nil?
  end

  def changed?
    false
  end

  def changed_attribute_names_to_save
    []
  end

  def save
    if @id.nil?
      @id = $next_id
      $next_id += 1
    end
    $db[:account_stats][@id] = self.dup
    true
  end

  def reload
    if $db[:account_stats][@id]
      record = $db[:account_stats][@id]
      @statuses_count = record.statuses_count
      @following_count = record.following_count
      @followers_count = record.followers_count
      @last_status_at = record.last_status_at
    end
    self
  end

  def self.upsert(attributes, on_duplicate:, unique_by:)
    account_id = attributes[:account_id]
    existing = $db[:account_stats].values.find { |r| r.account_id == account_id }

    if existing
      on_duplicate_str = on_duplicate.to_s
      if on_duplicate_str.include?('statuses_count + ')
        val = on_duplicate_str.match(/statuses_count \+ (-?\d+)/)[1].to_i
        existing.statuses_count += val
      end
      if on_duplicate_str.include?('followers_count + ')
        val = on_duplicate_str.match(/followers_count \+ (-?\d+)/)[1].to_i
        existing.followers_count += val
      end
      if on_duplicate_str.include?('following_count + ')
        val = on_duplicate_str.match(/following_count \+ (-?\d+)/)[1].to_i
        existing.following_count += val
      end

      if on_duplicate_str.include?('last_status_at') && attributes[:last_status_at]
        if existing.last_status_at.nil? || attributes[:last_status_at] > existing.last_status_at
          existing.last_status_at = attributes[:last_status_at]
        end
      end

      [{ 'id' => existing.id }]
    else
      new_stat = new(attributes)
      new_stat.save
      [{ 'id' => new_stat.id }]
    end
  end

  def self.sanitize_sql_array(ary)  
    # Simple mock
    "last_status_at = GREATEST(account_stats.last_status_at, '#{ary[1]}')"
  end
end

class AssociationMock
  def loaded?
    @loaded
  end
  def load!
    @loaded = true
  end
end

module ClassMacros
  def has_one(name, **)
    define_method(name) do
      var = instance_variable_get("@#{name}")
      unless var
        var = AccountStat.new(account_id: self.id)
        # Check if exists in db
        existing = $db[:account_stats].values.find { |r| r.account_id == self.id }
        if existing
          var = existing.dup
        end
        instance_variable_set("@#{name}", var)
        association(name).load!
      end
      var
    end

    define_method("#{name}=") do |val|
      instance_variable_set("@#{name}", val)
      association(name).load!
    end

    define_method("build_#{name}") do
      var = AccountStat.new(account_id: self.id)
      instance_variable_set("@#{name}", var)
      association(name).load!
      var
    end
  end

  def after_save(method)
    # mock
  end
end

class Account
  extend ClassMacros

  attr_accessor :id
  @@next_id = 1

  def initialize
    @id = @@next_id
    @@next_id += 1
  end

  def association(name)
    @associations ||= {}
    @associations[name] ||= AssociationMock.new
  end

  def save!
    account_stat&.save if association(:account_stat).loaded?
    true
  end

  def reload
    account_stat&.reload if association(:account_stat).loaded?
    self
  end

  require_relative './generated_spec/app/models/concerns/account/counters'
  include Account::Counters
end

# Fabricate mock
def Fabricate(name, attrs = {})
  case name
  when :account
    Account.new
  when :account_stat
    stat = AccountStat.new(attrs.merge(account_id: attrs[:account].id))
    stat.save
    attrs[:account].account_stat = stat
    stat
  else
    raise "Unknown fabrication #{name}"
  end
end


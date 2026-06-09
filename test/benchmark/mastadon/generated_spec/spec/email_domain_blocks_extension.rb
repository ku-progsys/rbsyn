# frozen_string_literal: true

require_relative './rails_helper'
require 'faker' # for Fabricator
require 'resolv'

class Thor
  class Error < StandardError; end

  def self.desc(*) end
  def self.long_desc(*) end
  def self.option(*) end

  def options
    {}
  end

  def say(message, color = nil)
    puts message
  end
  
  def shell
    self
  end
  
  def indent
    yield
  end

  def invoke(action, args = [], opts = {})
    @options = opts
    send(action, *args)
  end
  
  def options
    @options || {}
  end
end

class Mastodon
  module CLI
    class Base < Thor
      def self.exit_on_failure?
        true
      end

      private

      def fail_with_message(message)
        raise Thor::Error, message
      end
    end
  end
end

class DomainResource
  attr_reader :domain

  RESOLVE_TIMEOUT = 5

  def initialize(domain)
    @domain = domain
  end

  def mx
    Resolv::DNS.open do |dns|
      dns.timeouts = RESOLVE_TIMEOUT
      dns
        .getresources(domain, Resolv::DNS::Resource::IN::MX)
        .to_a
        .map { |mx| mx.exchange.to_s }
        .reject { |exchange| exchange.nil? || exchange.empty? }
    end
  end
end

$email_domain_blocks_db = {}
$email_domain_blocks_next_id = 1

class EmailDomainBlockQuery
  def initialize(records)
    @records = records
  end

  def where(conditions)
    result = @records.select do |r|
      conditions.all? do |k, v|
        r.send(k) == v
      end
    end
    EmailDomainBlockQuery.new(result)
  end

  def find_each(&block)
    @records.each(&block)
  end

  def count
    @records.length
  end
end

class EmailDomainBlock
  attr_accessor :id, :domain, :allow_with_approval, :parent_id, :other_domains
  attr_writer :parent

  def initialize(attrs = {})
    @id = attrs[:id]
    @domain = attrs[:domain]
    @allow_with_approval = attrs[:allow_with_approval] || false
    @parent_id = attrs[:parent_id] || (attrs[:parent] ? attrs[:parent].id : nil)
    @parent = attrs[:parent]
    @other_domains = attrs[:other_domains]
  end

  def parent
    @parent || EmailDomainBlock.find_by(id: @parent_id)
  end

  def save!
    if @id.nil?
      @id = $email_domain_blocks_next_id
      $email_domain_blocks_next_id += 1
    end
    $email_domain_blocks_db[@id] = self.dup
    true
  end

  def destroy
    $email_domain_blocks_db.delete(@id)
    true
  end

  def self.exists?(conditions)
    $email_domain_blocks_db.values.any? do |r|
      conditions.all? { |k, v| r.send(k) == v }
    end
  end

  def self.find_by(conditions)
    $email_domain_blocks_db.values.find do |r|
      conditions.all? { |k, v| r.send(k) == v }
    end
  end

  def self.where(conditions)
    EmailDomainBlockQuery.new($email_domain_blocks_db.values).where(conditions)
  end

  def self.parents
    where(parent_id: nil)
  end

  def self.count
    $email_domain_blocks_db.size
  end
end

# Reset DB before each spec
RSpec.configure do |config|
  config.before(:each) do
    $email_domain_blocks_db = {}
    $email_domain_blocks_next_id = 1
  end
end

def Fabricate(name, attrs = {})
  case name
  when :email_domain_block
    domain_val = attrs[:domain] || "domain#{rand(10000)}.com"
    block = EmailDomainBlock.new(attrs.merge(domain: domain_val))
    block.save!
    block
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

module CommandLineHelpers
  def output_results(*)
    output(
      include(*)
    ).to_stdout
  end
end

RSpec::Matchers.define_negated_matcher :not_output_results, :output_results
RSpec::Matchers.define_negated_matcher :not_change, :change

RSpec.configure do |config|
  config.include CommandLineHelpers
end

module DomainHelpers
  def configure_mx(domain:, exchange:, ip_v4_addr: '2.3.4.5', ip_v6_addr: 'fd00::2')
    resolver = instance_double(Resolv::DNS, :timeouts= => nil)

    allow(resolver).to receive(:getresources)
      .with(domain, Resolv::DNS::Resource::IN::MX)
      .and_return([double_mx(exchange)])
    allow(resolver)
      .to receive(:getresources)
      .with(domain, Resolv::DNS::Resource::IN::A)
      .and_return([])
    allow(resolver)
      .to receive(:getresources)
      .with(domain, Resolv::DNS::Resource::IN::AAAA)
      .and_return([])
    allow(resolver)
      .to receive(:getresources)
      .with(exchange, Resolv::DNS::Resource::IN::A)
      .and_return([double_resource_v4(ip_v4_addr)])
    allow(resolver)
      .to receive(:getresources)
      .with(exchange, Resolv::DNS::Resource::IN::AAAA)
      .and_return([double_resource_v6(ip_v6_addr)])
    allow(Resolv::DNS)
      .to receive(:open)
      .and_yield(resolver)
  end

  def configure_dns(domain:, results:)
    resolver = instance_double(Resolv::DNS, :timeouts= => nil)

    allow(resolver).to receive(:getresources)
      .with(domain, Resolv::DNS::Resource::IN::MX)
      .and_return(results)
    allow(resolver)
      .to receive(:getresources)
      .with(domain, Resolv::DNS::Resource::IN::A)
      .and_return(results)
    allow(resolver)
      .to receive(:getresources)
      .with(domain, Resolv::DNS::Resource::IN::AAAA)
      .and_return(results)
    allow(Resolv::DNS)
      .to receive(:open)
      .and_yield(resolver)
  end

  private

  def double_mx(exchange)
    instance_double(Resolv::DNS::Resource::MX, exchange: exchange)
  end

  def double_resource_v4(addr)
    instance_double(Resolv::DNS::Resource::IN::A, address: addr)
  end

  def double_resource_v6(addr)
    instance_double(Resolv::DNS::Resource::IN::AAAA, address: addr)
  end
end

RSpec.configure do |config|
  config.include DomainHelpers
end

RSpec.shared_examples 'CLI Command' do
  it 'configures Thor to exit on failure' do
    expect(described_class.exit_on_failure?).to be true
  end

  it 'descends from the CLI base class' do
    expect(described_class.new).to be_a(Mastodon::CLI::Base)
  end
end

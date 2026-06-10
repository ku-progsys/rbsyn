# frozen_string_literal: true

# require_relative "../../../../models/account"
# require_relative "../../../../models/account_stat"

require "rspec"
require 'rails'
require 'fabrication'
require "active_record"


# Establish the connection BEFORE requiring any file that uses ActiveRecord
ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)
require_relative "../../../../models/model_helper"
Fabrication.configure do |config|
  config.fabricator_path = 'fabricators'
  config.path_prefix = 'test'
end

#Rbsyn::ActiveRecord::Utils.load_schema

require_relative "../dependencies/cli/cache"
#require "fabrication" 
#require "../../../../models/model_helper"


def output_results(*)
  output(
    include(*)
  ).to_stdout
end

RSpec.shared_examples 'CLI Command' do
  it 'configures Thor to exit on failure' do
    expect(described_class.exit_on_failure?).to be true
  end

  it 'descends from the CLI base class' do
    expect(described_class.new).to be_a(Mastodon::CLI::Base)
  end
end


RSpec.describe Mastodon::CLI::Cache do
  subject { cli.invoke(action, arguments, options) }

  let(:cli) { described_class.new }
  let(:arguments) { [] }
  let(:options) { {} }

  it_behaves_like 'CLI Command'

  describe '#clear' do
    let(:action) { :clear }

    before { allow(Rails.cache).to receive(:clear) }

    it 'clears the Rails cache' do
      expect { subject }
        .to output_results('OK')
      expect(Rails.cache).to have_received(:clear)
    end
  end

  describe '#recount' do
    let(:action) { :recount }

    context 'with the `mastodon_accounts` argument' do
      let(:arguments) { ['mastodon_accounts'] }
      let(:mastodon_account_stat) { Fabricate(:mastodon_account_stat) }

      before do
        mastodon_account_stat.update(statuses_count: 123)
      end

      it 're-calculates account records in the cache' do
        expect { subject }
          .to output_results('OK')

        expect(mastodon_account_stat.reload.statuses_count).to be_zero
      end
    end

    context 'with the `mastodon_statuses` argument' do
      let(:arguments) { ['mastodon_statuses'] }
      let(:mastodon_status_stat) { Fabricate(:mastodon_status_stat) }

      before do
        mastodon_status_stat.update(replies_count: 123)
      end

      it 're-calculates mastodon_account records in the cache' do
        expect { subject }
          .to output_results('OK')

        expect(mastodon_status_stat.reload.replies_count).to be_zero
      end
    end

    context 'with an unknown type' do
      let(:arguments) { ['other-type'] }

      it 'Exits with an error message' do
        expect { subject }
          .to raise_error(Thor::Error, /Unknown/)
      end
    end
  end
end
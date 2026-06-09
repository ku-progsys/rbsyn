# frozen_string_literal: true
# Base is mocked in spec/support/email_domain_blocks_extension.rb


class Thor
  def self.desc(*) end
  def self.long_desc(*) end
  def self.option(*) end
end

class Mastodon
  module CLI
    class Base < Thor
      def self.exit_on_failure?
        true
      end
    end
  end
end
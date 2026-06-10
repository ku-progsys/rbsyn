# frozen_string_literal: true

require 'thor'




module Mastodon
  module CLI
    # ...
  end
end

require_relative 'progress_helper'

module Mastodon
  module CLI
    class Base < Thor
      include ProgressHelper # Provides parallelize_with_progress to Cache

      def self.exit_on_failure?
        true
      end

      private

      # CRITICAL: Required for the "unknown type" context test
      def fail_with_message(message)
        raise Thor::Error, message
      end
    end
  end
end


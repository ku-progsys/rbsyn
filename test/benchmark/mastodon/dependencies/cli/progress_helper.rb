module Mastodon::CLI
  module ProgressHelper
    def parallelize_with_progress(scope)
      # Check the concurrency expectation from Cache
      fail_with_message 'Cannot run with this concurrency setting' if options[:concurrency] < 1

      total = 0
      aggregate = 0

      # Mimic the iteration logic
      scope.each do |item|
        result = yield(item)
        total += 1
        aggregate += result.to_i if result.is_a?(Integer)
      end

      # Return the array expected by the caller: [total, aggregate]
      [total, aggregate]
    end
  end
end
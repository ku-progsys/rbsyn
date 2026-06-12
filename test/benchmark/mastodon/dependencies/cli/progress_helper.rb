# ...existing code...
module Mastodon::CLI
  module ProgressHelper
    # Simple, non-parallel stub for tests: run inline and return [total, aggregate].
    def parallelize_with_progress(scope, *args, **kwargs)
 
      total = 0
      aggregate = 0

      scope.each do |item|
        result = yield(item)
        total += 1
        aggregate += result.to_i if result.is_a?(Integer)
      end

      [total, aggregate]
    end
  end
end
# ...existing code...
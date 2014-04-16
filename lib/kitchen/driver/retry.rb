require 'fog'

module Kitchen
  # Provide a method to retry operations when API requests failed
  # due to throtlling.
  module Retry

    def with_retry_on_throttling(options = {}, &block)
      raise "block is required" unless block_given?
      retries = 0
      max_retries = options[:max_retries] || 10
      retry_delay = options[:retry_delay] || 3
      retry_backoff = 1.4142 + Random.rand
      success = false
      r = e = nil
      begin
        begin
          r = yield retries
          success = true
        rescue ::Fog::Compute::AWS::Error => e
          if e.message =~ /RequestLimitExceeded/
            success = false
            if max_retries - retries > 0
              delay = retry_delay * (retry_backoff ** retries)
              delay = delay.to_i
              puts e.message
              puts "Sleeping %0.2f seconds. Will retry %i more time(s)." % [delay, max_retries - retries]
              sleep delay
            end
            retries += 1
          else
            raise e
          end
        end
      end until success or retries > max_retries
      raise e unless success
      r
    end
  end
end


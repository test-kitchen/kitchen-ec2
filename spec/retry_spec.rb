require 'kitchen/driver/retry'


describe Kitchen::Retry do
  let(:o) do
    Class.new do
      include Kitchen::Retry
    end.new
  end

  it 'should retry on RequestLimitExceeded' do
    o.should_receive(:puts).with('RequestLimitExceeded => Request limit exceeded.')
    o.should_receive(:puts).with('Sleeping 1.00 seconds. Will retry 1 more time(s).')
    o.with_retry_on_throttling(:max_retries => 1, :retry_delay => 1) do
        raise ::Fog::Compute::AWS::Error.new('RequestLimitExceeded => Request limit exceeded.')
      end rescue nil
  end

end
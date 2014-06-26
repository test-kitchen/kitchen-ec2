require 'kitchen/driver/retry'


describe Kitchen::Retry do
  let(:o) do
    Class.new do
      include Kitchen::Retry
    end.new
  end

  it 'should retry on RequestLimitExceeded' do
    o.stub(:on_throttled)
    o.should_receive(:on_throttled).twice
    o.with_retry_on_throttling(:max_retries => 1) do
        raise ::Fog::Compute::AWS::Error.new('RequestLimitExceeded => Request limit exceeded.')
      end rescue nil
  end

end
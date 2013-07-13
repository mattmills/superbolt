require 'spec_helper'

describe Superbolt, 'the facade' do
  describe '.config' do
    after do
      Superbolt.instance_eval do
        @config = nil
      end
    end

    it "stores the default" do
      Superbolt.config.should == Superbolt::Config.new
    end

    it "can be customized" do
      Superbolt.config = {
        connection_key: 'SOME_RABBITMQ_URL'
      }

      Superbolt.config.env_connection_key.should == 'SOME_RABBITMQ_URL'
    end
  end

  describe '.queue' do
    it "creates a queue with the default config" do
      queue = double('queue')
      Superbolt::Queue.should_receive(:new)
        .with('queue_name', Superbolt.config)
        .and_return(queue)
      Superbolt.queue('queue_name').should == queue
    end
  end

  describe '.message' do
    it "sends messages via the messenger system" do
      queue = Superbolt.queue('activator_test')
      queue.clear
      Superbolt.env = 'test'
      Superbolt.app_name = 'bossanova'

      Superbolt.message
        .to('activator')
        .re('update')
        .send!({class: 'Advocate'})

      queue.pop.should == {
        'origin' => 'bossanova',
        'event' => 'update',
        'arguments' => {
          'class' => 'Advocate'
        }
      }
    end
  end
end

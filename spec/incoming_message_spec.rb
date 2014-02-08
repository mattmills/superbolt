require 'spec_helper'

describe Superbolt::IncomingMessage do
  let(:message){ Superbolt::IncomingMessage.new(delivery_info, payload, channel) }
  let(:payload){ { some: "message" }.to_json }
  let(:delivery_info) { double("info", delivery_tag: "tag") }
  let(:channel) { double("channel") }

  describe '#parse' do
    context 'payload is not json' do
      let(:payload) { 'foo' }

      it 'just returns the payload' do
        message.parse.should == payload
      end
    end

    context 'payload is json' do
      it "parses it to a hash" do
        message.parse.should == {'some' => 'message'}
      end

      context 'payload has a file' do
        let(:payload) { { 'arguments' => {'some_file' => {'file_hash' => 'yup'}} }.to_json } 
        let(:packer) { double('packer', perform: {'some_file' => 'some_file'} ) }
        
        it "uses FilePacker to rewrite files into a hash" do
          Superbolt::FileUnpacker.should_receive(:new)
            .with({'some_file' => {'file_hash' => 'yup'}})
            .and_return(packer)
          message.parse.should == {'arguments' => packer.perform}
        end
      end
    end
  end

  describe '#reject' do
    it "calls reject on the channel with the appropritate data and options" do
      channel.should_receive(:reject).with('tag', true)

      message.reject
    end

    it "can reject without requeuing" do
      channel.should_receive(:reject).with('tag', false)

      message.reject(false)
    end
  end

  describe "#ack" do
    it "calls acknowledge on the channel" do
      channel.should_receive(:acknowledge).with('tag')

      message.ack
    end
  end
end
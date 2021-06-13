require 'spec_helper'
require './spec/helpers/Client'

RSpec.describe Client do
  before(:all) do
    @client = Client.new("localhost",28561)
  end
  describe 'set command' do
    let(:storedValue) { "STORED" }
    let(:clientError) { "CLIENT_ERROR bad data chunk" }
    let(:expectedValue) {"VALUE testvar 0 9\ntestvalue\nEND"}
    let(:error) { "ERROR" }

    it 'should receive STORED message from server' do
      line = @client.storage_command("set","testvar","0","900","9","","testvalue")
      expect(line.strip).to eq(storedValue)
    end

    it 'we should be able to get stored data' do
      line = @client.storage_command("set","testvar","0","900","9","","testvalue")
      line = @client.retrieval_command("get",["testvar"])
      expect(line.strip).to eq(expectedValue)
    end

    context 'if bytes amount do not match' do
      it 'should return CLIENT_ERROR bad data chunk' do
        line = @client.storage_command("set","testvar","0","900","5","","morethan5bytes")
        expect(line.strip).to eq(clientError)
      end
    end
    context 'if missing param' do
      it 'should return ERROR' do
        line = @client.storage_command("set","testvar","","900","9","","testvalue")
        expect(line.strip).to eq(error)
      end
    end
  end
  after(:all) do
    @client.purge_keys
    @client.exit
  end
end

require 'spec_helper'
require 'clientclass'

RSpec.describe Client do
  before(:all) do
    @client = Client.new("localhost",28561)
  end
  describe 'set command' do
    context 'dataexists' do
      before(:each) do
        line = @client.set_command("testvar","0","900","9","testvalue")
      end

      it 'should store data successfully' do
        line = @client.get_command(["testvar"])
        expect(line.strip).to eq("VALUE testvar 0 9\ntestvalue\nEND")
      end
    end

    #ISOLATED TESTS THAT DO NOT NEED ANY BEFORE CODE
    it 'should receive STORED message from server if command correct' do
      line = @client.set_command("testvar","0","900","9","testvalue")
      expect(line.strip).to eq("STORED")
    end

    it 'should return ERROR if missing param' do
      line = @client.set_command("testvar","","900","9","testvalue")
      expect(line.strip).to eq("ERROR")
    end

    it 'should return CLIENT_ERROR bad data chunk if byte amounts do not match' do
      line = @client.set_command("testvar","0","900","5","morethan5bytes")
      expect(line.strip).to eq("CLIENT_ERROR bad data chunk")
    end
  end
  after(:all) do
    @client.purge_keys
    @client.exit
  end
end

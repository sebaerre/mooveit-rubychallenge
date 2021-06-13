require 'spec_helper'
require './spec/helpers/Client'

RSpec.describe Client do
  before(:all) do
    @client = Client.new("localhost",28561)
  end
  describe 'add command' do
    let(:storedValue) { "STORED" }
    let(:notStoredValue) { "NOT_STORED" }
    let(:clientError) { "CLIENT_ERROR bad data chunk" }
    let(:expectedValue) {"VALUE addNewKeyStoreDataSuccess 0 3\nbar\nEND"}
    let(:error) { "ERROR" }

    context 'if data exists for the provided key' do
      before(:each) do
        line = @client.storage_command("set","testvar","0","900","9","","testvalue")
      end
      it 'should return NOT_STORED' do
        line = @client.storage_command("add","testvar","0","900","9","","valuevalu")
        expect(line.strip).to eq(notStoredValue)
      end
    end
    context 'if data does not exist for the provided key' do
      it 'should receive STORED message from server' do
        line = @client.storage_command("add","addNewKeySuccess","0","900","3","","bar")
        expect(line.strip).to eq(storedValue)
      end
      it 'we should be able to get stored data' do
        line = @client.storage_command("add","addNewKeyStoreDataSuccess","0","900","3","","bar")
        line = @client.retrieval_command("get",["addNewKeyStoreDataSuccess"])
        expect(line.strip).to eq(expectedValue)
      end
    end
    context 'if missing param' do
      it 'should return ERROR' do
        line = @client.storage_command("add","testvar","","900","9","","testvalue")
        expect(line.strip).to eq(error)
      end
    end
    context 'if byte amounts do not match' do
      it 'should return CLIENT_ERROR bad data chunk' do
        line = @client.storage_command("add","testvar","0","900","5","","morethan5bytes")
        expect(line.strip).to eq(clientError)
      end
    end
  end
  after(:all) do
    @client.purge_keys
    @client.exit
  end
end

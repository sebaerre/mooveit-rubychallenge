require 'spec_helper'
require './spec/helpers/Client'

RSpec.describe Client do
  before(:all) do
    @client = Client.new("localhost",28561)
  end
  describe 'prepend command' do
    let(:storedValue) { "STORED" }
    let(:notStoredValue) { "NOT_STORED" }
    let(:clientError) { "CLIENT_ERROR bad data chunk" }
    let(:expectedValue) {"VALUE testvar 0 12\nbartestvalue\nEND"}
    let(:casKeyValue) {"12"}
    let(:error) { "ERROR" }

    context 'if data exists for the provided key' do
      before(:each) do
        line = @client.storage_command("set","testvar","0","900","9","","testvalue")
      end

      it 'should prepend data successfully' do
        line = @client.storage_command("prepend","testvar","0","900","3","","bar")
        line = @client.retrieval_command("get",["testvar"])
        expect(line.strip).to eq(expectedValue)
      end

      it 'should add the correct number of bytes' do
        line = @client.storage_command("prepend","testvar","0","900","3","","bar")
        line = @client.retrieval_command("get",["testvar"])
        expect(line.strip).to include(casKeyValue)
      end

      it 'should receive STORED message from server' do
        line = @client.storage_command("prepend","testvar","0","900","9","","testvalue")
        expect(line.strip).to eq(storedValue)
      end

      it 'should update the unique cas key' do
        line = @client.retrieval_command("gets",["testvar"])
        resultarr = line.split(" ")
        prevcaskey = resultarr[4]

        line = @client.storage_command("prepend","testvar","0","900","9","","testvalue")

        line = @client.retrieval_command("gets",["testvar"])
        resultarr = line.split(" ")
        expect(resultarr[4]).not_to eq(prevcaskey)
      end
    end

    context 'if byte amounts do not match' do
      it 'should return CLIENT_ERROR bad data chunk' do
        line = @client.storage_command("prepend","testvar","0","900","5","","morethan5bytes")
        expect(line.strip).to eq(clientError)
      end
    end
    context 'if data does not exist for the provided key' do
      it 'should return NOT_STORED' do
        line = @client.storage_command("prepend","doesnotexist","0","900","3","","bar")
        expect(line.strip).to eq(notStoredValue)
      end
    end
    context 'if missing param' do
      it 'should return ERROR' do
        line = @client.storage_command("prepend","testvar","","900","9","","testvalue")
        expect(line.strip).to eq(error)
      end
    end

  end
  after(:all) do
    @client.purge_keys
    @client.exit
  end
end

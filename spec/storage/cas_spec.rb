require 'spec_helper'
require './spec/helpers/Client'

RSpec.describe Client do
  before(:all) do
    @client = Client.new("localhost",28561)
  end
  describe 'cas command' do
    let(:storedValue) { "STORED" }
    let(:notStoredValue) { "NOT_STORED" }
    let(:notFoundValue) { "NOT_FOUND" }
    let(:existsValue) { "EXISTS" }
    let(:clientError) { "CLIENT_ERROR bad data chunk" }
    let(:expectedValue) {"VALUE testvar 0 12\nbartestvalue\nEND"}
    let(:casKeyValue) {"12"}
    let(:error) { "ERROR" }
    context 'if data exists for the provided key' do
      before(:each) do
        line = @client.storage_command("set","testvar","0","900","9","","testvalue")
      end

      context 'if the provided caskey is wrong' do
        it 'should return EXISTS' do
          line = @client.storage_command("cas","testvar","0","900","4","0","test")
          expect(line.strip).to eq(existsValue)
        end
      end
      context 'if the provided caskey is OK' do
        it 'should return STORED' do
          line = @client.retrieval_command("gets",["testvar"])

          resultarr = line.split(" ")
          caskey = resultarr[4]

          line = @client.storage_command("cas","testvar","0","900","4","#{caskey}","test")
          expect(line.strip).to eq(storedValue)
        end
      end
    end#end context

    context 'if the data does not exist for the provided key' do
      it 'should return NOT_FOUND' do
        line = @client.storage_command("cas","doesnotexist","0","900","9","5","testvalue")
        expect(line.strip).to eq(notFoundValue)
      end
    end
    context 'if missing param' do
      it 'should return ERROR' do
        line = @client.storage_command("cas","errorArgs","0","900","","5","testvalue")
        expect(line.strip).to eq(error)
      end
    end
    context 'if bytes amount do not match' do
      it 'should return CLIENT_ERROR bad data chunk' do
        line = @client.storage_command("cas","testvar","0","900","5","1","morethan5bytes")
        expect(line.strip).to eq(clientError)
      end
    end

  end#end describe cas

  after(:all) do
    @client.purge_keys
    @client.exit
  end

end#end describe client

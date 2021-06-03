require 'spec_helper'
require 'clientclass'

RSpec.describe Client do
  before(:all) do
    @client = Client.new("localhost",28561)
  end

  describe 'replace command' do
    context 'dataexists' do
      before(:each) do
        line = @client.set_command("testvar","0","900","9","testvalue")
      end

      it 'should receive STORED message from server if command correct and there is data for the provided key' do
        line = @client.replace_command("testvar","0","900","3","bar")
        expect(line.strip).to eq("STORED")
      end

      it 'should update data for the provided key if it exists' do
        line = @client.replace_command("testvar","0","900","5","asdfg")
        line = @client.get_command(["testvar"])
        expect(line.strip).to eq("VALUE testvar 0 5\nasdfg\nEND")
      end

      it 'should update the unique cas key if success' do
        line = @client.gets_command(["testvar"])
        resultarr = line.split(" ")
        prevcaskey = resultarr[4]

        line = @client.replace_command("testvar","0","900","9","testvalue")

          line = @client.gets_command(["testvar"])
          resultarr = line.split(" ")
          expect(resultarr[4]).not_to eq(prevcaskey)
      end

    end

    #ISOLATED TESTS THAT DO NOT NEED ANY BEFORE CODE
    it 'should return NOT_STORED if data is not set for the provided key' do
      line = @client.replace_command("unusedNewKey","0","900","4","test")
      expect(line.strip).to eq("NOT_STORED")
    end

    it 'should return ERROR if missing param' do
      line = @client.replace_command("testvar","","900","9","testvalue")
      expect(line.strip).to eq("ERROR")
    end

    it 'should return CLIENT_ERROR bad data chunk if byte amounts do not match' do
      line = @client.replace_command("testvar","0","900","5","morethan5bytes")
      expect(line.strip).to eq("CLIENT_ERROR bad data chunk")
    end

  end
  after(:all) do
    @client.purge_keys
    @client.exit
  end
end

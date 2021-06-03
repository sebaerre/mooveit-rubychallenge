require 'spec_helper'
require 'clientclass'

RSpec.describe Client do
  before(:all) do
    @client = Client.new("localhost",28561)
  end
  describe 'cas command' do
    context 'dataexists' do
      before(:each) do
        line = @client.set_command("testvar","0","900","9","testvalue")
      end

      it 'should return EXISTS when the provided caskey is wrong' do
        line = @client.cas_command("testvar","0","900","4","0","test")
        expect(line.strip).to eq("EXISTS")
      end

      it 'should return STORED when the provided caskey is OK' do
        line = @client.gets_command(["testvar"])

        resultarr = line.split(" ")
        caskey = resultarr[4]

        line = @client.cas_command("testvar","0","900","4","#{caskey}","test")
        expect(line.strip).to eq("STORED")
      end

    end#end context

#ISOLATED TESTS THAT DO NOT NEED ANY BEFORE CODE
it 'should return NOT_FOUND when presented with a key that does not exist' do
  line = @client.cas_command("doesnotexist","0","900","9","5","testvalue")
  expect(line.strip).to eq("NOT_FOUND")
end

it 'should return ERROR when missing args' do
  line = @client.cas_command("errorArgs","0","900","","5","testvalue")
  expect(line.strip).to eq("ERROR")
end



  end#end describe cas

  after(:all) do
    @client.purge_keys
    @client.exit
  end

end#end describe client

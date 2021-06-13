require 'spec_helper'
require './spec/helpers/clientclass'

RSpec.describe Client do
  before(:all) do
    @client = Client.new("localhost",28561)
    @client.storage_command("set","testvar","0","900","9","","testvalue")
    @client.storage_command("set","foo","0","900","3","","bar")
  end
  describe 'gets command' do
    let(:expectedValue) { /VALUE testvar 0 9 \d{1,}\ntestvalue\nEND/ }
    let(:expectedValues) { /VALUE testvar 0 9 \d{1,}\ntestvalue\nVALUE foo 0 3 \d{1,}\nbar\nEND/ }
    let(:error) { "ERROR" }


    context 'if no keys are provided' do
      it 'should return ERROR' do
        line = @client.retrieval_command("gets",[])
        expect(line.strip).to eq(error)
      end
    end

    context 'if keys are provided' do
      it 'should get stored data correctly + the unique cas key' do
        line = @client.retrieval_command("gets",["testvar"])
        expect(line.strip).to match(expectedValue)
      end

      it 'should ignore namevars that are not stored' do
        line = @client.retrieval_command("gets",["testvar","doesntexist"])
        expect(line.strip).to match(expectedValue)
      end

      it 'should get the data for all variables that exist + their unique cas keys' do
        line = @client.retrieval_command("gets",["testvar","foo"])
        expect(line.strip).to match(expectedValues)
      end
    end
  end
  after(:all) do
    @client.exit
  end
end

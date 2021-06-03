require 'spec_helper'
require 'clientclass'

RSpec.describe Client do
  before(:all) do
    @client = Client.new("localhost",28561)
    @client.set_command("testvar","0","900","9","testvalue")
    @client.set_command("foo","0","900","3","bar")
  end
  describe 'get command' do

    it 'should display errors if no keys are provided' do
      line = @client.get_command([])
      expect(line.strip).to eq("ERROR")
    end

    it 'should get stored data correctly' do
      line = @client.get_command(["testvar"])
      expect(line.strip).to eq("VALUE testvar 0 9\ntestvalue\nEND")
    end

    it 'should ignore namevars that are not stored' do
      line = @client.get_command(["testvar","doesntexist"])
      expect(line.strip).to eq("VALUE testvar 0 9\ntestvalue\nEND")
    end

    it 'should get the data for more than one variable if they exist' do
      line = @client.get_command(["testvar","foo"])
      expect(line.strip).to eq("VALUE testvar 0 9\ntestvalue\nVALUE foo 0 3\nbar\nEND")
    end

  end
  after(:all) do
    @client.exit
  end
end

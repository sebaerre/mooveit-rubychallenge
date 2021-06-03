require 'spec_helper'
require 'clientclass'

RSpec.describe Client do
  before(:all) do
    @client = Client.new("localhost",28561)
    @client.set_command("testvar","0","900","9","testvalue")
    @client.set_command("foo","0","900","3","bar")
  end
  describe 'gets command' do

    it 'should get stored data correctly + the cas unique key' do
      line = @client.gets_command(["testvar"])
      expect(line.strip).to match(/VALUE testvar 0 9 \d{1,}\ntestvalue\nEND/)
    end

    it 'should ignore namevars that are not stored' do
      line = @client.gets_command(["testvar","doesntexist"])
      expect(line.strip).to match(/VALUE testvar 0 9 \d{1,}\ntestvalue\nEND/)
    end

    it 'should get the data for more than one variable if they exist + their cas unique key' do
      line = @client.gets_command(["testvar","foo"])
      expect(line.strip).to match(/VALUE testvar 0 9 \d{1,}\ntestvalue\nVALUE foo 0 3 \d{1,}\nbar\nEND/)
    end

  end
  after(:all) do
    @client.exit
  end
end

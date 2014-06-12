require 'spec_helper'

describe PackagistCrawler do

  describe 'crawle_package' do

    it "succeeds" do
      License.count.should == 0
      described_class.crawle_package 'doctrine/annotations'
      License.count.should > 1
    end

  end

  describe 'get_first_level_list' do

    it "returns the list" do
      list = described_class.get_first_level_list
      list.should_not be_nil
      list.should_not be_empty
      list.count.should > 1
    end

  end

end

require 'spec_helper'

describe PackagistLicenseCrawler do

  describe 'crawle_package' do

    it "succeeds" do
      License.delete_all
      product = ProductFactory.create_new
      product.language = "PHP"
      product.prod_key = 'doctrine/annotations'
      product.save

      License.count.should == 0
      described_class.crawle_package 'doctrine/annotations'
      License.count.should > 1
    end

  end

end

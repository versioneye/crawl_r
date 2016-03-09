require 'spec_helper'

describe PhpeyeCrawler do


  describe 'crawl' do
    it 'crawles cakephp and skips all branches' do
      Product.delete_all
      expect( License.count ).to eq(0)
      expect( Product.count ).to eq(0)
      product = ProductFactory.create_for_composer "symfony/symfony", '3.0.3'
      expect( product.save ).to be_truthy
      expect( product.versions.first.tested_runtimes ).to be_nil
      PhpeyeCrawler.crawl
      expect( Product.count ).to eq(1)
      product = Product.first
      expect( product.versions.first.tested_runtimes ).to_not be_nil
      expect( product.versions.first.tested_runtimes ).to_not be_empty
    end
  end

end

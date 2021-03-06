require 'spec_helper'

describe GithubCrawler do


  describe 'crawl' do
    it 'crawles cakephp and skips all branches' do
      Product.delete_all
      expect( License.count ).to eq(0)
      expect( Product.count ).to eq(0)
      pr = ProductResource.new({url: "https://api.github.com/repos/nginx/nginx", name: "nginx/nginx", resource_type: "GitHub"})
      expect( pr.save ).to be_truthy
      GithubCrawler.crawl
      expect( Product.count ).to eq(1)
      product = Product.first
      expect( product.versions.count ).to eq(30)
      expect( product.dependencies.count ).to eq(0)
      expect( product.language ).to eq("C")
      expect( product.name ).to eq('nginx')
    end
  end

end

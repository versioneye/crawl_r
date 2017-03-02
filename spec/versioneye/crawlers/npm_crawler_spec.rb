require 'spec_helper'

describe NpmCrawler do
  let(:product1){
    Product.new(
      name: "NPM_MOCK",
      prod_key: "NPM_MOCK",
      version: '0.9',
      language: Product::A_LANGUAGE_NODEJS,
      prod_type: Project::A_TYPE_NPM
    )
  }
  
  describe "check_licenses" do
    after do
      License.delete_all
    end

    it "saves deprecated license hash-map" do
      license_doc = {
        'license' => {'type' => 'MIT', 'url' => 'http://www.opensource.org/mit'}
      }
      NpmCrawler.check_licenses(product1, product1[:version], license_doc)
      licenses = License.where(language: Product::A_LANGUAGE_NODEJS, prod_key: product1[:prod_key])
      expect(licenses.size).to eq(1)
      expect(licenses[0][:name]).to eq('MIT')
    end

    it "saves deprecated array of hash-maps of license type and urls" do
      licenses_doc = {
        "licenses" => [
          { 
            "type"  => "MIT",
            "url"   => "http://www.opensource.org/licenses/mit-license.php"
          }, 
          {
            "type"  => "Apache-2.0",
            "url"   => "http://opensource.org/licenses/apache2.0.php"
          }
        ]
      }
      NpmCrawler.check_licenses(product1, product1[:version], licenses_doc)
      
      licenses = License.where(language: Product::A_LANGUAGE_NODEJS, prod_key: product1[:prod_key])
      expect(licenses.size).to eq(2)
      expect(licenses[0][:name]).to eq('MIT')
      expect(licenses[1][:name]).to eq('Apache-2.0')
    end

    it "saves a new license from plain SPDX-ID string" do
      NpmCrawler.check_licenses(product1, product1[:version], {'license' => 'MIT'})
      licenses = License.where(language: Product::A_LANGUAGE_NODEJS, prod_key: product1[:prod_key])
      expect(licenses.size).to eq(1)
      expect(licenses[0][:name]).to eq('MIT')
    end

    it "saves all the dual-licenses from string with SPDX-ID ids" do
      NpmCrawler.check_licenses(product1, product1[:version], {'license' => '(MIT OR Apache-2.0)'})
      licenses = License.where(language: Product::A_LANGUAGE_NODEJS, prod_key: product1[:prod_key])
      expect(licenses.size).to eq(2)
      expect(licenses[0][:name]).to eq('MIT')
      expect(licenses[1][:name]).to eq('Apache-2.0')
    end
  end


  describe 'get_first_level_list' do
    it "returns the list" do
      list = described_class.get_first_level_list
      expect( list ).to_not be_nil
      expect( list.count > 1 ).to be_truthy
    end
  end

  describe 'crawl' do
    it 'crawles cakephp and skips all branches' do
      Product.delete_all
      expect( License.count ).to eq(0)
      expect( Product.count ).to eq(0)
      NpmCrawler.crawl true, ["stack-mapper"]
      expect( Product.count ).to eq(1)
      product = Product.first
      expect( product.versions.count > 1 ).to be_truthy
      expect( product.dependencies.count > 1 ).to be_truthy
      expect( License.count > 1 ).to be_truthy
    end
  end

  describe 'get_known_packages' do
    it 'returns the list of existing npm packages from db' do
      Product.delete_all
      request = ProductFactory.create_for_npm 'request', '1.0.0'
      expect( request.save ).to be_truthy
      chai = ProductFactory.create_for_npm 'chai', '1.0.0'
      expect( chai.save ).to be_truthy
      expect( Product.count ).to eq(2)

      packages = NpmCrawler.get_known_packages
      expect( packages ).to_not be_empty
      expect( packages.first ).to eq('request')
      expect( packages.last ).to eq('chai')
    end
  end

end

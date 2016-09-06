require 'spec_helper'

describe ComposerUtils do
  before do
    WebMock.enable! 
  end


  context "split_license" do
    it "returns list of licenseNames without surrounding spaces" do
      res = ComposerUtils.split_licenses(['MIT', '  GPL     '])
      expect(res[0]).to eq('MIT')
      expect(res[1]).to eq('GPL')
    end

    it "returns list of licenses after splitting string with ORs" do
      res = ComposerUtils.split_licenses('(LGPL-2.1 or GPL-3.0+)')
      expect(res).not_to be_nil
      expect(res[0]).to eq('LGPL-2.1')
      expect(res[1]).to eq('GPL-3.0+')
    end

    it "returns list of single license if it was plain string" do
      res = ComposerUtils.split_licenses('MIT')
      expect(res).not_to be_nil
      expect(res[0]).to eq('MIT')
    end
  end

  let(:product1){
    Product.new(
      name: 'PhpMock',
      prod_key: 'PhpMock',
      version: '1.2',
      prod_type: Project::A_TYPE_COMPOSER,
      language: Product::A_LANGUAGE_PHP
    )
  }

  context "create_license" do
    after do
      License.delete_all
    end
      
    it "saves a single license when plain license name" do
      ComposerUtils.create_license(product1, product1[:version], {'license' => 'MIT'})
      licenses = License.where(prod_key: product1[:prod_key], version: product1[:version])
      expect(licenses.size).to eq(1)
      expect(licenses.first[:name]).to eq('MIT')
    end

    it "saves multiple licenses when the license doc is an array" do
      ComposerUtils.create_license(product1, product1[:version], {'license' => ['MIT', 'BSD']})
      licenses = License.where(prod_key: product1[:prod_key], version: product1[:version])
      expect(licenses.size).to eq(2)
      expect(licenses[0][:name]).to eq('MIT')
      expect(licenses[1][:name]).to eq('BSD')
    end

    it "saves multiple licenses when the license dos is string of names" do
      ComposerUtils.create_license(product1, product1[:version], {'license' => '(MIT OR MPL)'})
      licenses = License.where(prod_key: product1[:prod_key], version: product1[:version])
      expect(licenses.size).to eq(2)
      expect(licenses[0][:name]).to eq('MIT')
      expect(licenses[1][:name]).to eq('MPL')
    end

    it "saves multiple licenses when the license field was passed without doc" do
      ComposerUtils.create_license(product1, product1[:version], "(MIT OR BSD)")
      licenses = License.where(prod_key: product1[:prod_key], version: product1[:version])
      expect(licenses.size).to eq(2)
      expect(licenses[0][:name]).to eq('MIT')
      expect(licenses[1][:name]).to eq('BSD')

    end
  end
end

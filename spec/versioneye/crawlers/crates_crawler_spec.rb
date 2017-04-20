require 'spec_helper'

describe CratesCrawler do
  let(:api_key){ ENV['CRATES_API_KEY'].to_s }
  let(:prod1_id){ 'nanomsg' }

  context "fetch_product_list" do
    it "returns expected data for first page" do
      VCR.use_cassette('crates/products_list') do
        products = CratesCrawler.fetch_product_list(api_key, 1)
        expect(products.is_a?(Array)).to be_truthy
        expect(products.count).to eq(100)
      end
    end

    it "returns empty list for non-existing page" do
      VCR.use_cassette('crates/empty_products_list') do
        products = CratesCrawler.fetch_product_list(api_key, 99999)
        expect(products.empty?).to be_truthy
      end
    end
  end

  context "fetch_product_details" do
    it "returns expected product details" do
      VCR.use_cassette('crates/product_details') do
        product_doc = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(product_doc.nil?).to be_falsey

        expect(product_doc.has_key?(:crate)).to be_truthy
        expect(product_doc[:crate][:id]).to eq(prod1_id)
        expect(product_doc.has_key?(:versions)).to be_truthy
      end
    end

    it "returns empty response when the product doesnt exists" do
      VCR.use_cassette('create/empty_product_details') do
        product_doc = CratesCrawler.fetch_product_details(api_key, 'yibberish-blaberish-0001')
        expect(product_doc.nil?).to be_truthy
      end
    end
  end
end

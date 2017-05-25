require 'spec_helper'

describe HexCrawler do
  let(:prod1){
    Product.new(
      language: HexCrawler::A_LANGUAGE_ELIXIR,
      prod_type: HexCrawler::A_TYPE_HEX,
      prod_key: 'abacus',
      name: 'abacus'
    )
  }

  let(:prod2){
    Product.new(
      language: HexCrawler::A_LANGUAGE_ELIXIR,
      prod_type: HexCrawler::A_TYPE_HEX,
      prod_key: 'anilixir',
      name: 'anilixir'
    )
  }

  let(:prod3){
     Product.new(
      language: HexCrawler::A_LANGUAGE_ELIXIR,
      prod_type: HexCrawler::A_TYPE_HEX,
      prod_key: 'cowboy',
      name: 'cowboy',
      version: '1.1.2'
    )

  }

  context "fetch_product_list" do
    it "returns correct first item from first page" do
      VCR.use_cassette('hex/product_list_page1') do
        res = HexCrawler.fetch_product_list(1)

        expect( res ).not_to be_nil
        expect(res.size).to eq(100)
        expect(res[0][:name]).to eq(prod1[:name])
      end
    end

    it "returns correct first item from second page" do
      VCR.use_cassette('hex/product_list_page2') do
        res = HexCrawler.fetch_product_list(2)

        expect( res ).not_to be_nil
        expect( res.size ).to eq(100)
        expect(res[0][:name]).to eq(prod2[:name])
      end
    end
  end

  context "fetch_product_details" do
    it "returns correct product details" do
      VCR.use_cassette('hex/product_details') do
        res = HexCrawler.fetch_product_details(prod3[:prod_key])

        expect(res).not_to be_nil
        expect(res[:name]).to eq(prod3[:name])
        expect(res[:releases].size).to eq(8)
      end
    end
  end

  context "fetch_product_version" do
    it "returns correct version details" do
      VCR.use_cassette('hex/product_version') do
        res = HexCrawler.fetch_product_version(prod3[:prod_key], prod3[:version])

        expect(res).not_to be_nil
        expect(res[:version]).to eq(prod3[:version])
      end
    end
  end
end

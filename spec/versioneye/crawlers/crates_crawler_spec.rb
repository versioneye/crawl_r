require 'spec_helper'

describe CratesCrawler do
  let(:api_key){ ENV['CRATES_API_KEY'].to_s }
  let(:prod1_id){ 'nanomsg' }
  let(:version1){ '0.6.0' }
  let(:owner1_doc){
    {
      avatar: "https://avatars.githubusercontent.com/u/565790?v=3",
      email: "dnfagnan@gmail.com",
      id: 2,
      kind: "user",
      login: "thehydroimpulse",
      name: "Daniel Fagnan",
      url: "https://github.com/thehydroimpulse"
    }
  }

  let(:dep1_doc){
    {
      crate_id: "libc",
      default_features: true,
      downloads: 0,
      features: [],
      id: 89992,
      kind: "normal",
      optional: false,
      req: "^0.2.11",
      target: nil,
      version_id: 28431
    }
  }

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
      VCR.use_cassette('crates/empty_product_details') do
        product_doc = CratesCrawler.fetch_product_details(api_key, 'yibberish-blaberish-0001')
        expect(product_doc.nil?).to be_truthy
      end
    end
  end

  context "fetch_version_dependencies" do
    it "returns expected product dependencies" do
      VCR.use_cassette('crates/version_dependencies') do
        deps = CratesCrawler.fetch_version_dependencies(api_key, prod1_id, version1)
        expect(deps.nil?).to be_falsey

        expect(deps.size).to eq(2)
        expect(deps[0][:crate_id]).to eq('libc')
        expect(deps[1][:crate_id]).to eq('nanomsg-sys')
      end
    end
  end

  context "fetch_product_owners" do
    it "returns expected package owners" do
      VCR.use_cassette('crates/product_owners') do
        owners = CratesCrawler.fetch_product_owners(api_key, prod1_id)
        expect(owners.nil?).to be_falsey
        expect(owners.size).to eq(2)
        expect(owners[0][:login]).to eq('thehydroimpulse')
        expect(owners[1][:login]).to eq('blabaere')
      end
    end
  end

  context "upsert_product" do
    it "save product data and returns updated product model" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate) ).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])

        expect(Product.all.count).to eq(1)
        expect(product_db[:language]).to eq('rust')
        expect(product_db[:prod_type]).to eq('crates')
        expect(product_db[:prod_key]).to eq(prod1_id)
        expect(product_db[:tags].size).to eq(6)
      end
    end
  end

  context "upsert_version" do
    it "adds a new version and returns updated version model" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy
        expect(res.has_key?(:versions)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        expect(product_db.versions.size).to eq(0)
        version_db = CratesCrawler.upsert_version(product_db, res[:versions].first)
        product_db.reload
        expect(product_db.versions.size).to eq(1)
        expect(version_db[:version]).to eq('0.6.2')
        expect(version_db[:released_at]).not_to be_nil
      end
    end
  end

  context "upsert_product_owner" do
    it "saves correctly the details of package owner" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy
        expect(res.has_key?(:versions)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        owner_db = CratesCrawler.upsert_product_owner(product_db, owner1_doc)
        expect(Author.all.count).to eq(1)
        expect(owner_db[:name_id]).to eq('daniel_fagnan')
        expect(owner_db[:name]).to eq(owner1_doc[:name])
        expect(owner_db[:role]).to eq('owner')
        expect(owner_db[:homepage]).to eq(owner1_doc[:url])
        expect(owner_db[:email]).to eq(owner1_doc[:email])
      end
    end
  end

  context "upsert_version_license" do
    it "saves correctly the details of license" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy
        expect(res.has_key?(:versions)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        lic_db = CratesCrawler.upsert_version_license(product_db, version1, 'MIT')
        expect(License.all.count).to eq(1)
        expect(lic_db[:name]).to eq('MIT')
        expect(lic_db[:language]).to eq(product_db[:language])
        expect(lic_db[:prod_key]).to eq(product_db[:prod_key])
        expect(lic_db[:version]).to eq(version1)

      end
    end
  end

  context "upsert_product_dependency" do
    it "saves correctly the product dependency" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        dep_db = CratesCrawler.upsert_product_dependency(product_db, version1, dep1_doc)
        expect(Dependency.all.count).to eq(1)
        expect(dep_db[:prod_type]).to eq(product_db[:prod_type])
        expect(dep_db[:language]).to eq(product_db[:language])
        expect(dep_db[:prod_key]).to eq(product_db[:prod_key])
        expect(dep_db[:prod_version]).to eq(version1)
        expect(dep_db[:scope]).to eq(Dependency::A_SCOPE_COMPILE)
        expect(dep_db[:version]).to eq(dep1_doc[:req])
        expect(dep_db[:name]).to eq(dep1_doc[:crate_id])
      end
    end
  end


  context "product links" do
    it "saves new Product url correclty" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        url_db = CratesCrawler.upsert_version_link(product_db, version1, "test", "url://a")
        expect(Versionlink.all.count).to eq(1)
        expect(url_db[:language]).to eq(product_db[:language])
        expect(url_db[:prod_key]).to eq(product_db[:prod_key])
        expect(url_db[:version_id]).to eq(version1)
        expect(url_db[:name]).to eq('test')
        expect(url_db[:link]).to eq('url://a')
      end
    end

    it "saves correctly urls from the product document" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        link1, _ = CratesCrawler.upsert_product_links(
          product_db, version1, res[:crate]
        )
        expect(Versionlink.all.count).to eq(3)
        expect(link1[:language]).to eq(product_db[:language])
        expect(link1[:prod_key]).to eq(product_db[:prod_key])
        expect(link1[:version_id]).to eq(version1)
        expect(link1[:name]).to eq('homepage')
        expect(link1[:link]).to eq(res[:crate][:homepage])
      end
    end

    it "saves correctly download url for binaries" do
      VCR.use_cassette('crates/product_details') do
        res = CratesCrawler.fetch_product_details(api_key, prod1_id)
        expect(res.nil?).to be_falsey
        expect(res.has_key?(:crate)).to be_truthy

        product_db = CratesCrawler.upsert_product(res[:crate])
        expect(Product.all.count).to eq(1)

        pkg_name = "#{product_db[:prod_key]}-#{version1}.crate"
        dl_path = "/api/v1/crates/nanomsg/0.6.0/download"
        dl_link = "#{CratesCrawler::API_HOST}/#{dl_path}"
        url_db = CratesCrawler.upsert_version_archive(
          product_db, version1, dl_path
        )

        expect(Versionarchive.all.count).to eq(1)
        expect(url_db[:language]).to eq(product_db[:language])
        expect(url_db[:prod_key]).to eq(product_db[:prod_key])
        expect(url_db[:version_id]).to eq(version1)
        expect(url_db[:name]).to eq(pkg_name)
        expect(url_db[:link]).to eq(dl_link)

      end
    end
  end
end

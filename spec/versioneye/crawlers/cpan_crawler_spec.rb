require 'spec_helper'

describe CpanCrawler do
  let(:all_releases_url){ "#{CpanCrawler::A_API_URL}/release/_search?scroll=2m" }
  let(:author_url){ "#{CpanCrawler::A_API_URL}/author/VTI" }
  let(:release_url){ "#{CpanCrawler::A_API_URL}/release/VTI/Routes-Tiny-0.16" }
  let(:module_url){ "#{CpanCrawler::A_API_URL}/module/Routes::Tiny" }
  let(:scroll_url){ "#{CpanCrawler::A_API_URL}/release/_search?scroll=2m&scroll_id=abc123" }
  let(:delete_scroll_url){ "#{CpanCrawler::A_API_URL}/release/_search"  }
  let(:search_url){ "#{CpanCrawler::A_API_URL}/_search/scroll?scroll=2m&scroll_id=abc123" }

  let(:release_json){ File.read("spec/fixtures/files/cpan/release.json") }
  let(:release_dt){ JSON.parse(release_json, {symbolize_names: true}) }
  let(:author_json){ File.read('spec/fixtures/files/cpan/author.json') }
  let(:author_dt){ JSON.parse(author_json, {symbolize_names: true}) }
  let(:page1_json){
    %Q[
      {
         "took" : 11,
         "_scroll_id" : "abc123",
         "timed_out" : false,
         "hits" : {
            "hits" : [
               {
                  "fields" : {
                     "author" : "VTI",
                     "name" : "Routes-Tiny-0.16"
                  },
                  "_id" : "AklzvuEytxSzSjvtsUW2o2MG1Lo",
                  "_index" : "cpan_v1",
                  "_type" : "release",
                  "_score" : null,
                  "sort" : [
                     0
                  ]
               }
            ],
            "max_score" : null,
            "total" : 269844
         },
         "_shards" : {
            "total" : 5,
            "successful" : 5,
            "failed" : 0
         }
      }
    ]
  }



  context "match_license" do
    it "matches perl license_id with spdx_id" do
      expect( CpanCrawler.match_license('perl_5')[:spdx_id] ).to eq('Artistic-1.0-Perl')
      expect( CpanCrawler.match_license('apache')[:spdx_id] ).to eq('Apache-2.0')
      expect( CpanCrawler.match_license('apache_2_0')[:spdx_id] ).to eq('Apache-2.0')
      expect( CpanCrawler.match_license('unknown')[:spdx_id]).to be_nil
    end
  end

  context "match_dependency_scope" do
    it "returns correct Dependency scope constants" do
      expect( CpanCrawler.match_dependency_scope('build') ).to eq(Dependency::A_SCOPE_COMPILE)
      expect( CpanCrawler.match_dependency_scope('develop') ).to eq(Dependency::A_SCOPE_DEVELOPMENT)
      expect( CpanCrawler.match_dependency_scope('runtime') ).to eq(Dependency::A_SCOPE_RUNTIME)
      expect( CpanCrawler.match_dependency_scope('test') ).to eq(Dependency::A_SCOPE_TEST)
    end
  end

  let(:product1){
    Product.new(
      name: 'Routes::Tiny',
      prod_key: 'Routes::Tiny',
      version: '0.16',
      prod_type: CpanCrawler::A_TYPE_CPAN,
      language: CpanCrawler::A_LANGUAGE_PERL
    )
  }

  context "upsert_version_license" do
    after :each do
      License.delete_all
    end

    it "saves a new version license" do
      expect(License.all.size).to eq(0)
      lic_db = CpanCrawler.upsert_version_license(product1, '0.16', 'artistic_2')

      expect(License.all.size).to eq(1)
      expect(lic_db).not_to be_nil
      expect(lic_db[:language]).to eq(product1[:language])
      expect(lic_db[:prod_key]).to eq(product1[:prod_key])
      expect(lic_db[:name]).to eq('Artistic-2.0')
      expect(lic_db[:spdx_id]).to eq('Artistic-2.0')
    end

    it "doesnt save a duplicate if trying to save it twice" do
      expect(License.all.size).to eq(0)
      lic_db = CpanCrawler.upsert_version_license(product1, '0.16', 'artistic_2')
      expect(License.all.size).to eq(1)

      lic_db = CpanCrawler.upsert_version_license(product1, '0.16', 'artistic_2')
      expect(License.all.size).to eq(1)
    end

    it "adds a new license after already existing license" do
      expect(License.all.size).to eq(0)
      lic_old = CpanCrawler.upsert_version_license(product1, '0.16', 'artistic_2')
      expect(License.all.size).to eq(1)

      lic_new = CpanCrawler.upsert_version_license(product1, '0.16', 'mit')
      expect(License.all.size).to eq(2)
      expect(lic_new[:prod_key]).to eq(lic_old[:prod_key])
      expect(lic_new[:language]).to eq(lic_old[:language])
      expect(lic_new[:name]).to eq('MIT')
      expect(lic_new[:spdx_id]).to eq('MIT')
    end
  end

  context "upsert_version_download" do
    after :each do
      Versionarchive.delete_all
    end

    it "saves download link correctly for the mocked data" do
      link_db = CpanCrawler.upsert_version_download(product1, '0.16', release_dt)

      expect(link_db).not_to be_nil
      expect(link_db[:prod_key]).to eq(product1[:prod_key])
      expect(link_db[:language]).to eq(product1[:language])
      expect(link_db[:version_id]).to eq(product1[:version])
      expect(link_db[:name]).to eq('Routes-Tiny-0.16.tar.gz')
      expect(link_db[:link]).to eq('https://cpan.metacpan.org/authors/id/V/VT/VTI/Routes-Tiny-0.16.tar.gz')
    end

    it "does not add another url if it already exists" do
      expect(Versionarchive.all.size).to eq(0)
      link_db = CpanCrawler.upsert_version_download(product1, '0.16', release_dt)
      expect(Versionarchive.all.size).to eq(1)

      link_db = CpanCrawler.upsert_version_download(product1, '0.16', release_dt)
      expect(Versionarchive.all.size).to eq(1)
      expect(link_db).not_to be_nil
      expect(link_db[:prod_key]).to eq(product1[:prod_key])
      expect(link_db[:language]).to eq(product1[:language])
      expect(link_db[:version_id]).to eq(product1[:version])
      expect(link_db[:name]).to eq('Routes-Tiny-0.16.tar.gz')
      expect(link_db[:link]).to eq('https://cpan.metacpan.org/authors/id/V/VT/VTI/Routes-Tiny-0.16.tar.gz')
    end
  end

  context "upsert_version_link" do
    after :each do
      Versionlink.delete_all
    end

    it "saves a new version link" do
      link_db = CpanCrawler.upsert_version_link(product1, '0.16', 'repo', 'ftp://a.spec')

      expect(Versionlink.all.size).to eq(1)
      expect(link_db).not_to be_nil
      expect(link_db[:language]).to eq(product1[:language])
      expect(link_db[:prod_key]).to eq(product1[:prod_key])
      expect(link_db[:version_id]).to eq(product1[:version])
      expect(link_db[:link]).to eq('ftp://a.spec')
      expect(link_db[:name]).to eq('repo')
    end

    it "doesnt save duplicate" do
      expect(Versionlink.all.size).to eq(0)
      link_db = CpanCrawler.upsert_version_link(product1, '0.16', 'repo', 'ftp://a.spec')
      expect(Versionlink.all.size).to eq(1)

      link_db = CpanCrawler.upsert_version_link(product1, '0.16', 'repo', 'ftp://a.spec')
      expect(Versionlink.all.size).to eq(1)
      expect(link_db).not_to be_nil
      expect(link_db[:language]).to eq(product1[:language])
      expect(link_db[:prod_key]).to eq(product1[:prod_key])
      expect(link_db[:version_id]).to eq(product1[:version])
      expect(link_db[:link]).to eq('ftp://a.spec')
      expect(link_db[:name]).to eq('repo')
    end
  end

  context "upsert_dependency" do
    after :each do
      Dependency.delete_all
    end

    it "saves a new dependency correctly" do
      dep_doc = release_dt[:dependency].first

      dep_db = CpanCrawler.upsert_dependency(dep_doc, product1[:prod_key], product1[:version])
      expect(dep_db).not_to be_nil
      expect(dep_db[:prod_type]).to eq(product1[:prod_type])
      expect(dep_db[:language]).to eq(product1[:language])
      expect(dep_db[:prod_version]).to eq(product1[:version])
      expect(dep_db[:dep_prod_key]).to eq(dep_doc[:module])
      expect(dep_db[:version]).to eq(dep_doc[:version])
      expect(dep_db[:scope]).to eq(dep_doc[:phase])
    end

    it "doesnt save duplicates " do
      dep_doc = release_dt[:dependency].first

      expect(Dependency.all.count).to eq(0)
      dep_db = CpanCrawler.upsert_dependency(dep_doc, product1[:prod_key], product1[:version])
      expect(Dependency.all.count).to eq(1)

      dep_db = CpanCrawler.upsert_dependency(dep_doc, product1[:prod_key], product1[:version])
      expect(Dependency.all.count).to eq(1)
      expect(dep_db).not_to be_nil
      expect(dep_db[:prod_type]).to eq(product1[:prod_type])
      expect(dep_db[:language]).to eq(product1[:language])
      expect(dep_db[:prod_version]).to eq(product1[:version])
      expect(dep_db[:dep_prod_key]).to eq(dep_doc[:module])
      expect(dep_db[:version]).to eq(dep_doc[:version])
      expect(dep_db[:scope]).to eq(dep_doc[:phase])
    end
  end

  context "upsert_developer" do
    after :each do
      Developer.delete_all
    end

    it "saves a new author correctly" do
      author_db = CpanCrawler.upsert_developer(product1, product1[:version], author_dt)
      expect(Developer.all.size).to eq(1)
      expect(author_db).not_to be_nil

      expect(author_db[:language]).to eq(product1[:language])
      expect(author_db[:prod_key]).to eq(product1[:prod_key])
      expect(author_db[:version]).to eq(product1[:version])
      expect(author_db[:email]).to eq(author_dt[:email].first)
      expect(author_db[:name]).to eq(author_dt[:asciiname])
      expect(author_db[:role]).to eq('author')
    end

    it "does not save duplicate author for same version release" do
      expect(Developer.all.size).to eq(0)
      author_db = CpanCrawler.upsert_developer(product1, product1[:version], author_dt)
      expect(Developer.all.size).to eq(1)

      author_db = CpanCrawler.upsert_developer(product1, product1[:version], author_dt)
      expect(Developer.all.size).to eq(1)

      expect(author_db).not_to be_nil
      expect(author_db[:language]).to eq(product1[:language])
      expect(author_db[:prod_key]).to eq(product1[:prod_key])
      expect(author_db[:version]).to eq(product1[:version])
      expect(author_db[:email]).to eq(author_dt[:email].first)
      expect(author_db[:name]).to eq(author_dt[:asciiname])
      expect(author_db[:role]).to eq('author')
    end
  end

  context "upsert_contributors" do
    after :each do
      Developer.delete_all
    end

    it "saves a project contributors correctly" do
      contribs = release_dt[:metadata][:x_contributors]

      contribs = CpanCrawler.upsert_contributors(product1, product1[:version], contribs)
      expect(Developer.all.size).to eq(7)
      expect(contribs[0][:name]).to eq('Sergey Zasenko')
      expect(contribs[0][:email]).to eq('d3fin3@gmail.com')
    end
  end

  context "upsert_product" do
    after :each do
      Product.delete_all
    end

    it "saves a new product from release data" do
      prod_db = CpanCrawler.upsert_product(nil, release_dt, product1[:prod_key])

      expect(prod_db).not_to be_nil
      expect(prod_db[:name]).to eq(product1[:name])
      expect(prod_db[:prod_key]).to eq(product1[:prod_key])
      expect(prod_db[:language]).to eq(product1[:language])
      expect(prod_db[:version]).to eq(product1[:version])
      expect(prod_db[:group_id]).to eq(release_dt[:author])
      expect(prod_db[:parent_id]).to eq(release_dt[:main_module])

    end
  end

  context "crawl_all" do
    before :each do
      FakeWeb.allow_net_connect = %r[^https?://localhost]
      FakeWeb.register_uri(:post, all_releases_url, {body: page1_json})
      FakeWeb.register_uri(:get, scroll_url, body: "[]")
      FakeWeb.register_uri(:post, scroll_url, body: "[]")

      FakeWeb.register_uri(:get, search_url, body: "[]")
      FakeWeb.register_uri(:get, author_url, body: author_json)
      FakeWeb.register_uri(:get, release_url, body: release_json)
      FakeWeb.register_uri(:delete, delete_scroll_url, body: "[]")
    end

    after :each do
      FakeWeb.allow_net_connect = true
      Product.delete_all
      Developer.delete_all
    end

    it "process first scroll, fetches 1st release, author details and saves correct results" do
      res = CpanCrawler.crawl
      expect(res).to be_truthy
      expect(Product.all.count).to eq(3)

      prod = Product.find_by(language: 'Perl', prod_key: 'Routes::Tiny')
      expect(prod).not_to be_nil
      expect(prod[:version]).to eq(product1[:version])
      expect(Developer.all.size).to eq(21)
      expect(Dependency.all.size).to eq(24)

      #it also saved other modules as products
      module2 = Product.find_by(language: 'Perl', prod_key: 'Routes::Tiny::Match')
      expect(module2).not_to be_nil
      expect(module2[:name]).to eq('Routes::Tiny::Match')
      expect(module2[:version]).to eq(product1[:version])
      expect(module2[:parent_id]).to eq(product1[:prod_key])

      module3 = Product.find_by(language: 'Perl', prod_key: 'Routes::Tiny::Pattern')
      expect(module3).not_to be_nil
      expect(module3[:name]).to eq('Routes::Tiny::Pattern')
      expect(module3[:version]).to eq(product1[:version])
      expect(module3[:parent_id]).to eq(product1[:prod_key])
    end
  end
end

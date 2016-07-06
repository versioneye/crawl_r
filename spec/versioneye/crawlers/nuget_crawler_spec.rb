require 'spec_helper'

describe NugetCrawler do
  let(:catalog_url){"https://api.nuget.org/v3/catalog0/index.json"}
  let(:page0_url){"https://api.nuget.org/v3/catalog0/page0.json"}
  let(:page1_url){"https://api.nuget.org/v3/catalog0/page1.json"}
  let(:prod0_url){
    "https://api.nuget.org/v3/catalog0/data/2015.02.01.06.22.45/adam.jsgenerator.1.1.0.json"
  }
  let(:prod1_url){
    "https://api.nuget.org/v3/catalog0/data/2015.02.01.06.34.14/structuremap.2.6.2.json"
  }
  let(:catalog_json){
    '{"@id":"https://api.nuget.org/v3/catalog0/index.json",
      "@type":["CatalogRoot","AppendOnlyCatalog","Permalink"],
      "commitId":"67020d57-a000-47c9-930c-a9a32d30426b",
      "commitTimeStamp":"2016-07-06T14:17:53.2190091Z",
      "count":1728,
      "nuget:lastCreated":"2016-07-06T14:17:12.017Z",
      "nuget:lastDeleted":"2016-06-17T21:07:14.8431644Z",
      "nuget:lastEdited":"2016-07-06T14:13:31.757Z",
      "items":[
        {"@id":"https://api.nuget.org/v3/catalog0/page0.json",
         "@type":"CatalogPage",
         "commitId":"00000000-0000-0000-0000-000000000000",
         "commitTimeStamp":"2015-02-01T06:30:11.7477681Z",
         "count": 1},
        {"@id":"https://api.nuget.org/v3/catalog0/page1.json",
         "@type":"CatalogPage",
          "commitId":"8bcd3cbf-74f0-47a2-a7ae-b7ecc50005d3",
          "commitTimeStamp":"2015-02-02T06:39:53.9553899Z",
          "count": 1}
        ]
      }' 
  }
  let(:page0_json){
    '{"@id": "https://api.nuget.org/v3/catalog0/page0.json",
      "@type": "CatalogPage",
      "commitId": "00000000-0000-0000-0000-000000000000",
      "commitTimeStamp": "2015-02-01T06:30:11.7477681Z",
      "count": 1,
      "items": [
        {"@id": "https://api.nuget.org/v3/catalog0/data/2015.02.01.06.22.45/adam.jsgenerator.1.1.0.json",
         "@type": "nuget:PackageDetails",
         "commitTimeStamp": "2015-02-01T06:22:45.8488496Z",
         "nuget:id": "Adam.JSGenerator",
         "nuget:version": "1.1.0",
         "commitId": "b3f4fc8a-7522-42a3-8fee-a91d5488c0b1"}
      ]
    }'
  }

  let(:page1_json){
    '{"@id": "https://api.nuget.org/v3/catalog0/page1.json",
      "@type": "CatalogPage",
      "commitId": "8bcd3cbf-74f0-47a2-a7ae-b7ecc50005d3",
      "commitTimeStamp": "2015-02-01T06:39:53.9553899Z",
      "count": 1,
      "items": [
        {"@id": "https://api.nuget.org/v3/catalog0/data/2015.02.01.06.34.14/structuremap.2.6.2.json",
         "@type": "nuget:PackageDetails",
         "commitId": "e5421e4c-fb0a-4fc0-8246-65dd5d4fdd09",
         "commitTimeStamp": "2015-02-01T06:34:14.750674Z",
         "nuget:id": "structuremap",
         "nuget:version": "2.6.2"}
      ]
    }'
  }
  let(:prod0_json){
    '{"@id": "https://api.nuget.org/v3/catalog0/data/2015.02.01.06.22.45/adam.jsgenerator.1.1.0.json",
      "authors": "Dave Van den Eynde,Wouter Demuynck",
      "catalog:commitId": "b3f4fc8a-7522-42a3-8fee-a91d5488c0b1",
      "catalog:commitTimeStamp": "2015-02-01T06:22:45.8488496Z",
      "created": "2011-01-07T07:49:35.947Z",
      "description": "Adam.JSGenerator helps producing snippets of JavaScript code from managed code.",
      "id": "Adam.JSGenerator",
      "isPrerelease": false,
      "language": "en-US",
      "lastEdited": "0001-01-01T00:00:00Z",
      "packageHash": "/2ow1BS6W2npy9nlNDM+Qxt0wvNmhJw6MzEE2pwFvmVgxWqTfCSbkU9RulDtH3BJL/6BbBDiBm8HcfO0Lhajgw==",
      "packageHashAlgorithm": "SHA512",
      "packageSize": 144008,
      "published": "2011-03-07T12:34:36.83Z",
      "requireLicenseAcceptance": false,
      "licenseUrl": "http://www.apache.org/licenses/LICENSE-2.0",
      "summary": "Adam.JSGenerator helps producing snippets of JavaScript code from managed code.",
      "version": "1.1.0"
    }'
  }
  #fake product with dependencies
  let(:prod1_json){
    '{"@id": "https://api.nuget.org/v3/catalog0/data/2015.02.01.06.34.14/structuremap.2.6.2.json",
      "authors": "Jeremy Miller",
      "catalog:commitId": "e5421e4c-fb0a-4fc0-8246-65dd5d4fdd09",
      "catalog:commitTimeStamp": "2015-02-01T06:34:14.750674Z",
      "created": "2011-02-19T05:12:31.237Z",
      "description": "StructureMap is a Dependency Injection / Inversion of Control tool for .Net that can be used to improve the architectural qualities of an object oriented system by reducing the mechanical costs of good design techniques. StructureMap can enable looser coupling between classes and their dependencies, improve the testability of a class structure, and provide generic flexibility mechanisms. Used judiciously, StructureMap can greatly enhance the opportunities for code reuse by minimizing direct coupling between classes and configuration mechanisms.",
      "id": "structuremap",
      "isPrerelease": false,
      "language": "en-US",
      "lastEdited": "0001-01-01T00:00:00Z",
      "licenseUrl": "https://github.com/structuremap/structuremap/raw/master/LICENSE.TXT",
      "packageHash": "uNFqyLzN5x0gLF1dwUg3u4ZAjbFPD8wuHzVGl8iAFKJCg1F8xpCRVleeM7TKCfo28htAXThgR8dDmpq7B8lb7A==",
      "packageHashAlgorithm": "SHA512",
      "packageSize": 414696,
      "projectUrl": "http://structuremap.net/structuremap/",
      "published": "2011-02-19T05:12:46.86Z",
      "requireLicenseAcceptance": false,
      "summary": "StructureMap is a Dependency Injection / Inversion of Control tool for .Net",
      "version": "2.6.2",
      "dependencyGroups": [
        {"@id": "https://api.nuget.org/v3/catalog0/data/2016.07.06.12.13.57/ravendb.client.3.5.0-rc-35143.json#dependencygroup/.netframework4.5",
        "@type": "PackageDependencyGroup",
        "targetFramework": ".NETFramework4.5"
        },
        {"@id": "https://api.nuget.org/v3/catalog0/data/2016.07.06.12.13.57/ravendb.client.3.5.0-rc-35143.json#dependencygroup/.netstandard1.6",
         "@type": "PackageDependencyGroup",
         "dependencies": [
            {"@id": "https://api.nuget.org/v3/catalog0/data/2016.07.06.12.13.57/ravendb.client.3.5.0-rc-35143.json#dependencygroup/.netstandard1.6/microsoft.csharp",
             "@type": "PackageDependency",
             "id": "Microsoft.CSharp",
             "range": "[4.0.1, )"}
          ]}
        ]
    }'
  }
 
  describe 'is_same_date' do
    it "compares 2 datestring correctly" do
      expect(
        NugetCrawler.is_same_date("2015-02-02", "2015-02-02T06:39:53.9553899Z")
      ).to be_truthy

      expect(
        NugetCrawler.is_same_date("2015-02-01", "2015-02-02T06:39:53.9553899Z")
      ).to be_falsey
    end
  end

  describe 'fetch_json' do
    it "parses catalog response correctly" do
      FakeWeb.register_uri(:get, catalog_url, body: catalog_json)

      res = NugetCrawler.fetch_json catalog_url
      expect( res ).to_not be_nil
      expect( res[:items].count ).to eq(2)
    end
  end

  describe 'crawl' do
    it "crawls only page0 products when date is added" do
      Product.delete_all
      expect( License.count ).to eq(0)
      expect( Product.count ).to eq(0)

      FakeWeb.register_uri(:get, catalog_url, body: catalog_json)
      FakeWeb.register_uri(:get, page0_url, body: page0_json)
      FakeWeb.register_uri(:get, prod0_url, body: prod0_json)

      NugetCrawler.crawl '2015-02-01'

      expect( Product.count ).to eq(1)
      product = Product.first

      p "#-- product: ", product
      expect(product.prod_key).to eq('Adam.JSGenerator')
      expect(product.language).to eq('CSharp')
      expect(product.prod_type).to eq('Nuget')
      expect(product.versions.count).to eq(1)
      expect(product.versions.first.version).to eq("1.1.0")
      expect(product.dependencies.count).to eq(0)
      expect(License.count).to eq(1)
    end
  end


end

require 'spec_helper'

describe SecuritySensiolabsCrawler do

  describe 'crawle_scurity' do

    it "succeeds" do
      product = ProductFactory.create_for_composer 'firebase/php-jwt', "1.9.0"
      product.save.should be_truthy
      product.versions.push( Version.new( { :version => "1.9.1" } ) )
      product.versions.push( Version.new( { :version => "2.0.0" } ) )
      product.save.should be_truthy

      described_class.crawl
      
      product = Product.fetch_product "PHP", 'firebase/php-jwt'
      product.version_by_number('1.9.0').sv_ids.should_not be_empty
      product.version_by_number('2.0.0').sv_ids.should be_empty
    end

  end

end

require 'spec_helper'

describe BowerStarter do

  describe 'crawl' do
    it 'crawles cakephp and skips all branches' do
      Product.delete_all
      expect( Product.count ).to eq(0)
      token = Settings.instance.github_client_secret

      name = 'reactive-storage'
      url = 'git://github.com/bobtail-dev/bobtail-storage.git'

      VCR.use_cassette('bower/register_package') do
        BowerStarter.register_package(name, url, token)
      end

      expect( Product.count ).to eq(1)
      expect( Dependency.count > 1 ).to be_truthy
    end
  end

end

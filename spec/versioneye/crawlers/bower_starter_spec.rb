require 'spec_helper'

describe BowerStarter do

  describe 'crawl' do
    it 'crawles cakephp and skips all branches' do
      Product.delete_all
      expect( Product.count ).to eq(0)
      token = '07d9d399f1a8ff7880be12d168e48283380a9eb8'
      name = 'reactive-storage'
      url = 'git://github.com/rmehlinger/reactive-storage.git'
      BowerStarter.register_package name, url, token
      expect( Product.count ).to eq(1)
      expect( Dependency.count > 1 ).to be_truthy
    end
  end

end

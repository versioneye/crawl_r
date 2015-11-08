class ChefCrawler < Versioneye::Crawl

# https://supermarket.chef.io/api/v1/cookbooks
# https://supermarket.chef.io/api/v1/cookbooks?start=10
# https://supermarket.chef.io/api/v1/cookbooks/bash-cve-2014-6271
# https://supermarket.chef.io/api/v1/cookbooks/bash-cve-2014-6271/versions/0.1.1
# https://supermarket.chef.io/api/v1/cookbooks/aegir2/versions/0.1.9

  A_CHEF_REGISTRY_INDEX = 'https://supermarket.chef.io/api/v1/cookbooks'


  def self.logger
    ActiveSupport::Logger.new('log/chef.log')
  end


  def self.crawl serial = false
    packages = get_first_level_list
    packages.each do |name|
      crawl_package name
    end
  end


  def self.get_first_level_list
    cookbooks = []
    start = 0
    while 1 == 1
      resp = JSON.parse HTTParty.get( A_CHEF_REGISTRY_INDEX ).response.body
      break if resp['items'].empty?
      break if start > 20

      resp['items'].each do |item|
        cookbooks << item['cookbook_name']
      end
      start += 10
      p start
    end
    cookbooks
  end


  def self.crawl_package name
    logger.info "crawl: #{name}"
    url = "#{A_CHEF_REGISTRY_INDEX}/#{name}"
    package = JSON.parse HTTParty.get( url ).response.body
    product = Product.find_or_create_by(:language => Product::A_LANGUAGE_CHEF, :prod_key => name.downcase )
    product.prod_type = Project::A_TYPE_CHEF
    product.name = name
    product.name_downcase = name.downcase
    product.description = package['description']
    product.downloads   = package['metrics']['downloads']['total']
    product.add_tag( package['category'] )

    Versionlink.create_project_link product.language, product.prod_key, package['external_url'], 'URL'
    Versionlink.create_project_link product.language, product.prod_key, package['source_url'], 'Source'
    Versionlink.create_project_link product.language, product.prod_key, package['issues_url'], 'Issues'
    if !package['maintainer'].to_s.empty?
      developer = Developer.find_or_create_by(
        :language => product.language,
        :prod_key => product.prod_key,
        :developer => package['maintainer'],
        :name => package['maintainer'])
      developer.save
    end

    package['versions'].each do |version_link|
      handle_version product, version_link
    end

    product.save
  rescue => e
    self.logger.error "ERROR in crawl_package: #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.handle_version product, version_link
    package = JSON.parse HTTParty.get( version_link ).response.body
    product.add_version package['version']
    product.version = package['version'] if product.version.to_s.empty? || product.version.eql?('0.0.0+NA')

    License.find_or_create product.language, product.prod_key, package['version'], package['license']

    link = "https://supermarket.chef.io/cookbooks/#{product.name}"
    Versionlink.create_project_link product.language, product.prod_key, link, 'Cookbook'

    Versionarchive.find_or_create_by(
      :language => product.language,
      :prod_key => product.prod_key,
      :version_id => package['version'],
      :link => package['file'],
      :name => 'download' )

    return if package['dependencies'].to_s.empty?

    package['dependencies'].keys.each do |key|
      dependency = Dependency.find_or_create_by(
        :prod_type => Project::A_TYPE_CHEF,
        :language => product.language,
        :prod_key => product.prod_key,
        :prod_version => package['version'],
        :dep_prod_key => key.downcase,
        :version => package['dependencies'][key],
        :name => key )
      dependency.save
      dependency.update_known
    end
  rescue => e
    self.logger.error "ERROR in handle_version: #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end

end

class BiicodeCrawler < Versioneye::Crawl


  def self.logger
    ActiveSupport::BufferedLogger.new('log/biicode.log')
  end


  def self.crawl
    p "crawl ..."
    Settings.instance.reload_from_db GlobalSetting.new
    
    index = 'https://webapi.biicode.com/v1/misc/blocks'
    body = JSON.parse HTTParty.get( index ).response.body
    blocks = body['blocks']

    blocks.each do |block| 
      process block  
    end
    nil 
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  def self.process block_name 
    block_url = "https://webapi.biicode.com/v1/blocks/#{block_name}"
    block = JSON.parse HTTParty.get( block_url ).response.body

    product = init_product block_name
    product.description = block['description']
    product.version = block['version']
    product.save 

    p "#{block_name} - #{block['description']} - #{block['version']}"
    
    versions_url = "https://webapi.biicode.com/v1/misc/versions/#{block_name}"
    versions = JSON.parse HTTParty.get( versions_url ).response.body
    versions.each do |version_obj| 
      process_version product, version_obj
    end
  end


  def self.process_version product, version_obj
    key = version_obj.keys.first 
    released_string = version_obj[key]

    verso = product.version_by_number key
    return nil if verso

    create_new_verison product, key, released_string
  end


  def self.create_new_verison product, version_string, released_string
    version_db                 = Version.new({version: version_string})
    version_db.released_string = released_string
    version_db.released_at     = date_from released_string
    product.versions.push version_db
    product.reindex = true
    product.save

    self.logger.info " -- Biicode package: #{product.prod_key} -- with new version: #{version_string}"

    CrawlerUtils.create_newest product, version_string, logger
    CrawlerUtils.create_notifications product, version_string, logger

    # links 
    # tags 
    # dependencies 
    # licenses 
  end


  def self.init_product name
    product = Product.find_by_lang_key( Product::A_LANGUAGE_BIICODE, name.downcase )
    return product if product

    self.logger.info " -- New Biicode Package - #{name}"
    Product.new({
      :prod_type => Project::A_TYPE_BIICODE, 
      :language => Product::A_LANGUAGE_BIICODE, 
      :prod_key => name.downcase, 
      :name => name.downcase, 
      :name_downcase => name.downcase, 
      :reindex => true})
  end


  def self.date_from released_string
    DateTime.parse(released_string)
  rescue => e 
    logger.error e.message
    nil 
  end


end

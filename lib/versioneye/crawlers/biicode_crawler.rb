class BiicodeCrawler < Versioneye::Crawl


  # def self.logger
  #   if !defined?(@@log) || @@log.nil?
  #     @@log = Versioneye::DynLog.new("log/biicode.log", 10).log
  #   end
  #   @@log
  # end


  # def self.crawl
  #   Settings.instance.reload_from_db GlobalSetting.new

  #   index = 'https://webapi.biicode.com/v1/misc/blocks'
  #   body = JSON.parse HTTParty.get( index ).response.body
  #   blocks = body['blocks']

  #   blocks.each do |block|
  #     process block
  #   end
  #   nil
  # rescue => e
  #   logger.error e.message
  #   logger.error e.backtrace.join("\n")
  # end


  # def self.process block_name
  #   msg = "process #{block_name}"
  #   self.logger.info msg
  #   p msg

  #   block_url = "https://webapi.biicode.com/v1/blocks/#{block_name}"
  #   block     = JSON.parse HTTParty.get( block_url ).response.body

  #   tags_url  = "https://webapi.biicode.com/v1/blocks/#{block_name}/tags"
  #   tags_json = JSON.parse HTTParty.get( block_url ).response.body
  #   tags      = tags_json['tags']
  #   tags      = ["CPP"] if tags.nil? || tags.empty?

  #   product = init_product block_name
  #   product.description = block['description']
  #   product.version = block['version']
  #   product.tags = tags
  #   product.save

  #   versions_url = "https://webapi.biicode.com/v1/misc/versions/#{block_name}"
  #   versions = JSON.parse HTTParty.get( versions_url ).response.body
  #   versions.each do |version_obj|
  #     process_version product, version_obj, block
  #   end
  # rescue => e
  #   logger.error "#{block_name} - #{e.message}"
  #   logger.error e.backtrace.join("\n")
  # end


  # def self.process_version product, version_obj, block
  #   key = version_obj.keys.first
  #   released_string = version_obj[key]

  #   verso = product.version_by_number key
  #   return nil if verso

  #   create_new_verison product, key, released_string, block
  # end


  # def self.create_new_verison product, version_string, released_string, block
  #   version_db                 = Version.new({version: version_string})
  #   version_db.released_string = released_string
  #   version_db.released_at     = date_from released_string
  #   version_db.status = fetch_status block, released_string
  #   version_db.tag    = fetch_tag block, released_string

  #   product.versions.push version_db
  #   product.reindex = true
  #   product.save

  #   msg = " -- Biicode package: #{product.name} -- with new version: #{version_string}"
  #   self.logger.info msg
  #   p msg

  #   CrawlerUtils.create_newest product, version_string, logger
  #   CrawlerUtils.create_notifications product, version_string, logger

  #   create_links product, version_string, released_string, block
  #   create_dependencies product, version_string
  #   create_license product, version_string, released_string, block
  # end


  # def self.create_license product, version_string, released_string, block
  #   repo_name = fetch_gh_repo_name block, released_string
  #   branch = fetch_gh_branch block, released_string
  #   LicenseCrawler.process_github repo_name, branch, product, version_string
  # end


  # def self.create_links product, version_string, released_string, block
  #   scm_url = fetch_url block, released_string
  #   Versionlink.create_versionlink Product::A_LANGUAGE_BIICODE, product.prod_key, version_string, scm_url, "SCM"

  #   biicode_url = "https://www.biicode.com/#{product.name}"
  #   Versionlink.create_versionlink Product::A_LANGUAGE_BIICODE, product.prod_key, version_string, biicode_url, "Biicode"
  # end


  # def self.create_dependencies product, version_string
  #   dep_url = "https://webapi.biicode.com/v1/blocks/#{product.name}/#{version_string}/requirements"
  #   requirements = JSON.parse HTTParty.get( dep_url ).response.body
  #   return nil if requirements.nil? || requirements.empty?

  #   requirements.each do |requirement|
  #     prod_key = "#{requirement['owner']}/#{requirement['creator']}/#{requirement['block_name']}/#{requirement['branch']}"
  #     req_vers = requirement['time']

  #     dep = Dependency.find_by( Product::A_LANGUAGE_BIICODE, product.prod_key, version_string, prod_key, req_vers, prod_key.downcase )
  #     next if dep

  #     dependency = Dependency.new({:name => prod_key, :version => req_vers,
  #       :dep_prod_key => prod_key.downcase, :prod_key => product.prod_key,
  #       :prod_version => version_string, :scope => Dependency::A_SCOPE_COMPILE, :prod_type => Project::A_TYPE_BIICODE,
  #       :language => Product::A_LANGUAGE_BIICODE })
  #     dependency.save
  #     dependency.update_known
  #   end
  # rescue => e
  #   logger.error e.message
  #   logger.error e.backtrace.join("\n")
  # end


  # def self.fetch_status block, released_string
  #   return nil if block.nil? || block.empty?
  #   return nil if block['deltas'].to_a.empty?

  #   block['deltas'].each do |verso|
  #     return verso['tag'] if verso['datetime'].eql?(released_string)
  #   end
  #   nil
  # rescue => e
  #   logger.error e.message
  #   nil
  # end


  # def self.fetch_tag block, released_string
  #   return nil if block.nil? || block.empty?
  #   return nil if block['deltas'].to_a.empty?

  #   block['deltas'].each do |verso|
  #     return verso['versiontag'] if verso['datetime'].eql?(released_string) && !verso['versiontag'].to_s.empty?
  #   end
  #   nil
  # rescue => e
  #   logger.error e.message
  #   nil
  # end


  # def self.fetch_url block, released_string
  #   return nil if block.nil? || block.empty?
  #   return nil if block['deltas'].to_a.empty?

  #   block['deltas'].each do |verso|
  #     next if verso['origin'].nil? || verso['origin'].empty?

  #     return verso['origin']['url'] if verso['datetime'].eql?(released_string)
  #   end
  #   nil
  # rescue => e
  #   logger.error e.message
  #   nil
  # end


  # def self.fetch_gh_repo_name block, released_string
  #   return nil if block.nil? || block.empty?
  #   return nil if block['deltas'].to_a.empty?

  #   block['deltas'].each do |verso|
  #     next if verso['origin'].nil? || verso['origin'].empty?
  #     next if verso['origin']['service'].casecmp('Github') != 0

  #     if verso['datetime'].eql?(released_string)
  #       return "#{verso['origin']['username']}/#{verso['origin']['reponame']}"
  #     end
  #   end
  #   nil
  # rescue => e
  #   logger.error e.message
  #   nil
  # end


  # def self.fetch_gh_branch block, released_string
  #   return nil if block.nil? || block.empty?
  #   return nil if block['deltas'].to_a.empty?

  #   block['deltas'].each do |verso|
  #     next if verso['origin'].nil? || verso['origin'].empty?
  #     next if verso['origin']['service'].casecmp('Github') != 0

  #     if verso['datetime'].eql?(released_string)
  #       return verso['origin']['branch']
  #     end
  #   end
  #   nil
  # rescue => e
  #   logger.error e.message
  #   nil
  # end


  # def self.init_product name
  #   product = Product.find_by_lang_key( Product::A_LANGUAGE_BIICODE, name.downcase )
  #   return product if product

  #   Product.new({
  #     :prod_type => Project::A_TYPE_BIICODE,
  #     :language => Product::A_LANGUAGE_BIICODE,
  #     :prod_key => name.downcase,
  #     :name => name,
  #     :name_downcase => name.downcase,
  #     :reindex => true})
  # end


  # def self.date_from released_string
  #   DateTime.parse(released_string)
  # rescue => e
  #   logger.error e.message
  #   nil
  # end


end

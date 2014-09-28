class CocoapodsCrawler < Versioneye::Crawl


  def logger
    ActiveSupport::BufferedLogger.new('log/cocoapods.log')
  end


  def run cmd_string
    logger.info "Running: $ #{cmd_string}"
    `#{cmd_string}`
  end


  def self.crawl
    self.new.crawl
  end


  def crawl
    p "crawl ..."
    Settings.instance.reload_from_db GlobalSetting.new
    crawl_primary
    crawl_secondary
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  def crawl_primary
    p "crawl_primary ..."
    cocoa_git = Settings.instance.cocoapods_spec_git
    cocoa_url = Settings.instance.cocoapods_spec_url
    cocoa_dir = Settings.instance.cocoapods_spec_dir
    if cocoa_git.to_s.empty? || cocoa_dir.to_s.empty?
      p 'no cocoa_git registered'
    else
      crawl_repo cocoa_git, cocoa_dir, cocoa_url
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end

  def crawl_secondary
    return if Settings.instance.respond_to?("cocoapods_spec_git_2") == false
    return if Settings.instance.respond_to?("cocoapods_spec_url_2") == false
    return if Settings.instance.respond_to?("cocoapods_spec_dir_2") == false

    p "crawl_secondary ..."

    cocoa_git = Settings.instance.cocoapods_spec_git_2
    cocoa_url = Settings.instance.cocoapods_spec_url_2
    cocoa_dir = Settings.instance.cocoapods_spec_dir_2
    if !cocoa_git.to_s.empty? && !cocoa_dir.to_s.empty?
      crawl_repo cocoa_git, cocoa_dir, cocoa_url
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  def crawl_repo cocoa_git, cocoa_dir, base_url
    run "git clone #{cocoa_git} #{cocoa_dir}"
    run "(cd #{cocoa_dir} && git pull)"

    i = 0
    logger.info "start reading podspecs"
    all_spec_files( cocoa_dir ) do |filepath|
      i += 1
      logger.info "Parse CocoaPods Spec ##{i}: #{filepath}"
      parse_spec filepath, base_url
    end

    logger.info "start reading podspecs json"
    all_spec_json_files(cocoa_dir) do |filepath|
      i += 1
      logger.info "Parse CocoaPods Spec JSON ##{i}: #{filepath}"
      parse_spec filepath, base_url
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  def parse_spec filepath, base_url
    # parse every podspec file
    parser  = CocoapodsPodspecParser.new( base_url )
    product = parser.parse_file filepath
    if product
      ProductService.update_version_data product, false
      product.save
    else
      logger.warn 'NO PRODUCT'
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  # traverse directory, search for .podspec files
  def all_spec_json_files(dir, &block)
    Dir.glob "#{dir}/**/*.podspec.json" do |filepath|
      block.call filepath
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end

  # traverse directory, search for .podspec files
  def all_spec_files(dir, &block)
    Dir.glob "#{dir}/**/*.podspec" do |filepath|
      block.call filepath
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


end

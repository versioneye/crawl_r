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
    git_url = Settings.instance.cocoapods_spec_git
    dir = Settings.instance.cocoapods_spec

    run "git clone #{git_url} #{dir}"
    run "(cd #{dir} && git pull)"

    i = 0
    all_spec_files do |filepath|
      i += 1
      logger.info "Parse CocoaPods Spec ##{i}: #{filepath}"
      p "Parse CocoaPods Spec ##{i}: #{filepath}"
      parse_spec filepath
    end
  end

  def parse_spec filepath
    # parse every podspec file
    parser  = CocoapodsPodspecParser.new
    product = parser.parse_file filepath
    if product
      ProductService.update_version_data product, false
      product.save
    else
      logger.warn 'NO PRODUCT'
    end
  rescue => e
    logger.error e.message
  end

  # traverse directory, search for .podspec files
  def all_spec_files(&block)
    dir = Settings.instance.cocoapods_spec
    Dir.glob "#{dir}/**/*.podspec" do |filepath|
      block.call filepath
    end
  end

end

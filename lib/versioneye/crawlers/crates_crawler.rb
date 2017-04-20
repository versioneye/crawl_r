class CratesCrawler < Versioneye::Crawl

  API_URL = "https://crates.io/api/v1"

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/crates.log", 10).log
    end
    @@log
  end

  def self.crawl(api_key)
    api_key = api_key.to_s.strip

    if api_key.empty?
      logger.error "CRATES_API_KEY is not set - will stop crawler"
      return
    end

    logger.info "Going to crawl rust packages on the crates.io"
    crawl_product_list(api_key)
    logger.info "Done!"
  end


  def self.crawl_product_list(api_key, page_nr = 1, per_page = 100)
    logger.info "going to crawl product list from #{page_nr}, per_page: #{per_page} "
    loop do
      products = fetch_product_list(api_key, page_nr, per_page)
      if products.empty?
        logger.info "Stopping crawl_product_list after #{page_nr} due empty response"
        break
      end

      products.to_a.each do |product|
        crawl_product_details api_key, product[:id], product[:max_version]
      end

      page_nr += 1
    end

    logger.info "Done with crawling product lists"
  end

  def self.crawl_product_details(api_key, product_id, latest_version, ignore_existing = true)
    product_exists = Product.where(
      language: 'rust', #TODO replace with Product::A_LANGUAGE_RUST
      prod_type: 'crates', #TODO replace with Product::A_TYPE_CRATES
      prod_key: product_id,
      version: latest_version
    ).first

    if product_exists and ignore_existing
      logger.info "ignoring #{product_db} as it already exists on database and has no new releases"
      return
    end

    product_doc = fetch_product_details product_id
    if product_doc.nil?
      logger.error "Failed to fetch product details for #{product_id}"
      return
    end

    product_db = upsert_product(product_doc[:crate])
    product_doc[:versions].each do |version_doc|
      crawl_version_details(product_db, version_doc)
    end

    #TODO: create_newest, create_notifications

  end

  def self.crawl_version_details(product_db, version_doc)
    #crawl dependencies
    #create_download
    #create_versionlinks
    #create_license
    #create_author / owners


  end

  def self.upsert_product(product_doc)
    product_db = Product.where(
      language: 'rust', #TODO replace with Product::A_LANGUAGE_RUST
      prod_type: 'crates', #TODO replace with Product::A_TYPE_CRATES
      prod_key: product_doc[:id],
    ).first_or_create

    product_db.update(
      name_downcase: product_doc[:id].to_s.downcase,
      prod_key_dc: product_doc[:id].downcase,
      tags: product_doc[:categories].to_a
    );

    product_db
  end

  def self.upsert_version(product_db, version_doc)

  end

  #origins of the urls
  #https://github.com/rust-lang/crates.io/blob/master/src/lib.rs
  def self.fetch_product_list(api_key, page_nr, per_page = 100)
    resource_url = "#{API_URL}/crates?page=#{page_nr.to_i}&per_page=#{per_page}&api_key=#{api_key}"
    res = fetch_json resource_url
    res[:crates].to_a if res
  end

  def self.fetch_product_details(api_key, product_id)
    resource_url = "#{API_URL}/crates/#{product_id}?api_key=#{api_key}"
    fetch_json resource_url
  end


end

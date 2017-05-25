class HexCrawler < Versioneye::Crawl
  A_API_URL = 'https://hex.pm/api'
  A_MAX_PAGE = 10000 #TODO: increase when Elixir has more than 1M packages

  #TODO: use constants from the core
  A_TYPE_HEX = 'Hex'
  A_LANGUAGE_ELIXIR = "Elixir"

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/hex.log", 10).log
    end
    @@log
  end

  def self.crawl_product_list(page_nr = 1, per_page = 100, async = false)
    logger.info "crawl_product_list: fetching products on the page.#{page_nr}"

    n = 0
    loop do
      if page_nr > A_MAX_PAGE
        log.error "crawl_product_list: too deep product list tree #{A_MAX_PAGE}"
        break
      end

      products = fetch_product_list(page_nr, per_page)
      if products.to_a.empty?
        logger.info "crawl_product_list: stopping paging as no more products"
        break
      end

      products.each do |product_doc|
        prod_db = save_product(product_doc)
        crawl_product_details(prod_db, product_db, async)
        n += 1
      end

      page_nr += 1
    end

    logger.info "crawl_product_list: crawled #{page_nr} pages and #{n} products"
    n
  end

  def self.crawl_product_details(prod_db, product_doc, async)
    version_labels = product_doc[:releases].to_a.reduce([]) do |acc, r|
      acc << r[:version]
      acc
    end

    #fire ASYNC tasks
    if async
      #HexOwnerProducer.new prod_name[:name]
      #version_labels.each do |version|
      #   HexVersionProducer.new(prod_db[:prod_key], version
      #end
    else
      crawl_product_owners(prod_db[:prod_key])
      version_labels.each do |version|
        crawl_product_version(prod_db[:prod_key], version)
      end
    end
  end

  def self.crawl_product_owners(prod_key)
    #TODO: finish
  end

  #-- persistance helpers
  def self.save_product(product_doc)
    prod_db = upsert_product(product_doc)

    # save product urls
    product_doc[:meta][:links].each do |name, url|
      upsert_product_link(prod_db, name, url)
    end

    # save product licenses
    product_doc[:meta][:licenses].each do |spdx_id|
      upsert_product_license(prod_db, spdx_id)
    end

    #add product developers
    product_doc[:meta][:developers].each do |spdx_name|
      upsert_product_developer(prod_db, owner_name)
    end
  end

  def self.upsert_product(product_doc)
    prod_db = Product.where(
      language: A_LANGUAGE_ELIXIR,
      prod_type: A_TYPE_HEX,
      prod_key: product_doc[:name],
      name: product_doc[:name]
    ).first_or_create

    prod_db.update(
      description: product_doc[:meta][:description],
      downloads: product_doc[:downloads][:all].to_i
    )
    prod_db.save

    prod_db
  end

  def self.upsert_product_link(prod_db, name, url)
    url_db = Versionlink.where(
      language: prod_db[:language],
      prod_key: prod_db[:prod_key],
      url: url.to_s.strip
    ).first_or_create

    url_db.update(
      name: name.to_s.strip
    )

    url_db.save
    url_db
  end

  def self.upsert_product_license(prod_db, spdx_id)
    return if spdx_id.to_s.empty?

    License.where(
      language: prod_db[:language],
      prod_key: prod_db[:prod_key],
      spdx_id: spdx_id.to_s.strip
    ).first_or_create
  end

  #-- fetcher functions
  def self.fetch_product_list(page_nr, per_page = 100)
    page_nr ||= 1
    fetch_json "#{A_API_URL}/packages?page=#{page_nr}&per_page=#{per_page}"
  end

  def self.fetch_product_details(pkg_id)
    pkg_id = pkg_id.to_s.strip
    fetch_json "#{A_API_URL}/packages/#{pkg_id}"
  end

  def self.fetch_product_version(pkg_id, version_label)
    pkg_id = pkg_id.to_s.strip
    fetch_json "#{A_API_URL}/packages/#{pkg_id}/releases/#{version_label}"
  end
end

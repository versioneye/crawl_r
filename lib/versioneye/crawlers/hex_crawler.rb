require 'time'

class HexCrawler < Versioneye::Crawl

  A_API_URL = 'https://hex.pm/api'
  A_MAX_PAGE = 10000 # 10_000 * 100 packages, it used to stop rogue loops
  A_API_LIMIT = 100
  A_TIMEOUT  = 10
  A_MAX_RETRIES = 12
  A_MIN_REMAINING = 5

  @@remaining = 0 # be pessimistic and make it check before fetching content

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/hex.log", 10).log
    end
    @@log
  end


  # it crawl all the products from the list
  def self.crawl(page_nr = 1, per_page = 100)
    logger.info "crawl_product_list: fetching products on the page.#{page_nr}"

    n = 0
    loop do
      if page_nr > A_MAX_PAGE
        logger.error "crawl_product_list: hit the limit of max_pages at #{A_MAX_PAGE}"
        break
      end

      products = fetch_product_list(page_nr, per_page)
      if products.to_a.empty?
        logger.info "crawl_product_list: stopping paging as no more products"
        break
      end

      products.each do |product_doc|
        prod_db = save_product(product_doc)
        crawl_product_details(prod_db, product_doc)
        n += 1
      end

      page_nr += 1
    end

    logger.info "crawl_product_list: crawled #{page_nr} pages and #{n} products"
    n
  end


  def self.crawl_product_details(prod_db, product_doc, skip_existing = true)
    return nil if product_doc[:releases].nil? || product_doc[:releases].empty?

    product_doc[:releases].each do |release|
      version = release[:version]
      next if prod_db.version_by_number(version)

      crawl_product_version(prod_db.prod_key, version)
      prod_db.version = version
      prod_db.save
    end
    ProductService.update_version_data(prod_db)
    prod_db
  end


  def self.crawl_product_version(prod_key, version)
    logger.info "crawl_product_version: fetching #{prod_key} => #{version}"

    version_doc = fetch_product_version(prod_key, version)
    return if version_doc.nil?

    save_product_version(prod_key, version_doc)
  end


#-- persistance helpers

  def self.save_product(product_doc)
    prod_db = upsert_product(product_doc)

    crawl_product_owners( prod_db[:prod_key] )

    meta = product_doc[:meta]
    if meta.nil?
      log.error "save_product: product response has no meta information for #{product_doc[:name]}"
      return prod_db
    end

    # save product urls
    meta[:links].to_a.each do |name, url|
      upsert_product_link(prod_db, name, url)
    end

    # save product licenses
    meta[:licenses].to_a.each do |license_name|
      upsert_product_license(prod_db, license_name)
    end

    # add product developers
    meta[:maintainers].to_a.each do |owner_name|
      upsert_product_maintainer(prod_db, owner_name.to_s)
    end

    prod_db.reload
    prod_db
  end


  def self.crawl_product_owners(prod_key)
    logger.info "crawl_product_owners: pulling owners for #{prod_key}"

    owners = fetch_product_owners(prod_key)
    return if owners.nil?

    owners.to_a.each do |owner_doc|
      upsert_product_owner(prod_key, owner_doc)
    end
  end


  def self.save_product_version(prod_key, version_doc)
    prod_db = Product.fetch_product Product::A_LANGUAGE_ELIXIR, prod_key
    if prod_db.nil?
      logger.error "save_product_version: found no such product `#{prod_key}`"
      return
    end

    upsert_version(prod_db, version_doc)

    # Dependencies
    version_doc[:requirements].to_a.each do |dep_id, dep_doc|
      upsert_dependency(prod_db, version_doc[:version], dep_doc)
    end
  end


  def self.upsert_version(prod_db, version_doc)
    logger.info "save_product_version: saving version details #{prod_db} => #{version_doc[:version]}"

    prod_db.add_version version_doc[:version].to_s
    version_db = prod_db.version_by_number version_doc[:version].to_s

    status = if version_doc[:retirement]
               "deprecated"
             else
               "stable"
             end


    version_db.update(
      status: status,
      released_at: parse_date(version_doc),
      released_string: version_doc[:inserted_at].to_s,
      downloads: version_doc[:downloads]
    )

    version_db
  end


  def self.parse_date version_doc
    DateTime.parse version_doc[:inserted_at]
  rescue => e
    logger.error e.message
    nil
  end


  def self.upsert_product(product_doc)
    prod_db = Product.where(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_type: Project::A_TYPE_HEX,
      prod_key: product_doc[:name]
    ).first_or_create

    prod_db.update(
      name: product_doc[:name],
      prod_key_dc: product_doc[:name].to_s.downcase,
      description: product_doc[:meta][:description],
      downloads: product_doc[:downloads][:all].to_i
    )
    prod_db.save

    prod_db
  end


  def self.upsert_dependency(prod_db, prod_version, dep_doc)
    dep_db = Dependency.where(
      language: prod_db.language,
      prod_type: prod_db.prod_type,
      prod_key: prod_db.prod_key,
      prod_version: prod_version,
      dep_prod_key: dep_doc[:app]
    ).first_or_initialize

    dep_scope = (dep_doc[:optional] == true) ? Dependency::A_SCOPE_OPTIONAL : Dependency::A_SCOPE_COMPILE

    dep_db.update(
      name: dep_doc[:app],
      scope: dep_scope,
      version: dep_doc[:requirement]
    )

    dep_db.save
    dep_db
  end


  def self.upsert_product_link(prod_db, name, url)
    url_db = Versionlink.where(
      language: prod_db[:language],
      prod_key: prod_db[:prod_key],
      link: url.to_s.strip
    ).first_or_create

    url_db.update(
      name: name.to_s.strip
    )

    url_db.save
    url_db
  end


  def self.upsert_product_license(prod_db, license_name)
    return if license_name.to_s.empty?

    lic = License.where(
      language: prod_db[:language],
      prod_key: prod_db[:prod_key],
      name: license_name.to_s.strip
    ).first_or_create

    if lic.errors.full_messages.size > 0
      logger.error "Failed to save license #{license_name} for #{prod_db}"
      logger.error "\tReason: #{lic.errors.full_messages.to_sentence}"
      return
    end

    lic
  end


  # saves product authors and maintainers
  def self.upsert_product_maintainer(prod_db, dev_name)
    dev_name = dev_name.to_s.strip
    dev_email = nil

    match = dev_name.match(/(.*)<(.*)>/i)
    if match
      dev_name = match[1]
      dev_email = match[2]
    end

    dev = Developer.where(
      language: prod_db[:language],
      prod_key: prod_db[:prod_key],
      name: dev_name
    ).first_or_create
    dev.email = dev_email
    dev.save
    dev
  end


  # save people who manage releases
  def self.upsert_product_owner(prod_key, owner_doc)
    dev_name = owner_doc[:full_name]
    dev_name ||= owner_doc[:username]

    dev = Developer.where(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_key: prod_key,
      name: dev_name
    ).first_or_create

    dev.email = owner_doc[:email]
    dev.role = "owner"
    dev.contributor = true

    begin
      owner_doc[:handles][:twitter]
      owner_doc[:handles][:github]
    rescue => e
      logger.error "Failed to store handles in upsert_product_owner() " + e.message
    end

    dev
  end

  # Checks request limits and will sleep until re-try * A_TIMEOUT is over
  # it will not use X-RateLimit-Reset value as syncing epochs
  # over timezone adds unnecessary complexity, it simpler to re-try after pause
  def self.check_request_limit(times = 1)
    if times > A_MAX_RETRIES
      logger.error "check_request_limit: run out of re-tries. will stop execution"
      exit
    end

    @@remaining -= 1 #decrease global counter, so every fetcher will make it go down

    # avoid wasting requests when there's enough luck
    if @@remaining > A_MIN_REMAINING
      logger.info "check_request_limit: #{@@remaining} request left"
      return
    end

    #if there's not enough
    res = HTTParty.head A_API_URL
    if res and res.code >= 200 and res.code < 300
      remaining = res.headers["x-ratelimit-remaining"].to_i
    else
      # after API error, expect that we run out of luck
      remaining = 0
    end

    @@remaining = remaining # memorize the new value

    if remaining < A_MIN_REMAINING
      total_timeout = times * A_TIMEOUT #it will wait longer after each re-try
      logger.info "check_request_limit: will pause for #{total_timeout} seconds"
      sleep total_timeout
      check_request_limit(times + 1)
    end
  end


  #-- fetcher functions
  def self.fetch_product_list(page_nr, per_page = 100)
    check_request_limit

    page_nr ||= 1
    fetch_json "#{A_API_URL}/packages?page=#{page_nr}&per_page=#{per_page}"
  end

  def self.fetch_product_details(pkg_id)
    check_request_limit

    pkg_id = pkg_id.to_s.strip
    fetch_json "#{A_API_URL}/packages/#{pkg_id}"
  end

  def self.fetch_product_owners(pkg_id)
    check_request_limit

    pkg_id = pkg_id.to_s.strip
    fetch_json "#{A_API_URL}/packages/#{pkg_id}/owners"
  end

  def self.fetch_product_version(pkg_id, version_label)
    check_request_limit

    pkg_id = pkg_id.to_s.strip
    fetch_json "#{A_API_URL}/packages/#{pkg_id}/releases/#{version_label}"
  end

end

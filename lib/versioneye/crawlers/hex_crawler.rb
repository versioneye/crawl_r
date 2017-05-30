require 'time'

class HexCrawler < Versioneye::Crawl
  A_API_URL = 'https://hex.pm/api'
  A_MAX_PAGE = 10000 # 10_000 * 100 packages, it used to stop rogue loops

  #TODO: use constants from the core
  A_TYPE_HEX = 'Hex'
  A_LANGUAGE_ELIXIR = "Elixir"

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
        log.error "crawl_product_list: hit the limit of max_pages at #{A_MAX_PAGE}"
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
    #TODO: return if product has no changes
    existing_versions = prod_db.versions.to_a.map(&:version).to_set
    version_labels = product_doc[:releases].to_a.reduce([]) do |acc, r|
      if !existing_versions.include?(r[:version]) or skip_existing == false
        acc << r[:version]
      end

      acc
    end

    if version_labels.empty?
      logger.info "crawl_product: skipping #{prod_db} - no new versions"
      return prod_db
    end

    crawl_product_owners(prod_db[:prod_key])
    version_labels.each do |version|
      crawl_product_version(prod_db[:prod_key], version)
    end

    ProductService.update_version_data(prod_db)

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

  def self.crawl_product_version(prod_key, version)
    logger.info "crawl_product_version: fetching #{prod_key} => #{version}"

    version_doc = fetch_product_version(prod_key, version)
    return if version_doc.nil?

    save_product_version(prod_key, version_doc)
  end

#-- persistance helpers


  def self.save_product(product_doc)
    prod_db = upsert_product(product_doc)

    meta = product_doc[:meta]
    if meta.nil?
      log.error "save_product: product response has no meta details: #{product_doc}"
      return prod_db
    end

    # save product urls
    meta[:links].to_a.each do |name, url|
      upsert_product_link(prod_db, name, url)
    end

    # save product licenses
    meta[:licenses].to_a.each do |spdx_id|
      upsert_product_license(prod_db, spdx_id)
    end

    #add product developers
    meta[:maintainers].to_a.each do |owner_name|
      upsert_product_maintainer(prod_db, owner_name.to_s)
    end

    prod_db.reload
    prod_db
  end

  def self.save_product_version(prod_key, version_doc)
    prod_db = Product.where(
      language: A_LANGUAGE_ELIXIR,
      prod_key: prod_key
    ).first

    if prod_db.nil?
      logger.error "save_product_version: found no such product `#{prod_key}`"
      return
    end

    upsert_version(prod_db, version_doc)
    version_doc[:requirements].to_a.each do |dep_id, dep_doc|
      upsert_dependency(prod_db, version_doc[:version], dep_doc)
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

  def self.upsert_version(prod_db, version_doc)
    logger.info "save_product_version: saving version details #{prod_db} => #{version_doc[:version]}"

    version_db = prod_db.versions.where(
      version: version_doc[:version]
    ).first_or_initialize

    status = if version_doc[:retirement]
               "deprecated"
             else
               "stable"
             end

    release_dt = DateTime.parse version_doc[:inserted_at]

    version_db.update(
      status: status,
      released_at: release_dt,
      released_string: release_dt.to_s
    )

    version_db
  end

  def self.upsert_dependency(prod_db, prod_version, dep_doc)
    dep_db = Dependency.where(
      language: prod_db[:language],
      prod_type: prod_db[:prod_type],
      prod_key: prod_db[:prod_key],
      prod_version: prod_version,
      dep_prod_key: dep_doc[:app]
    ).first_or_initialize

    dep_scope = (dep_doc[:optional] == true) ? Dependency::A_SCOPE_OPTIONAL : Dependency::A_SCOPE_RUNTIME

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

  def self.upsert_product_license(prod_db, spdx_id)
    return if spdx_id.to_s.empty?

    lic = License.where(
      language: prod_db[:language],
      prod_key: prod_db[:prod_key],
      name: spdx_id.to_s.strip
    ).first_or_create

    if lic.errors.full_messages.size > 0
      logger.error "Failed to save license #{spdx_id} for #{prod_db}"
      logger.error "\tReason: #{lic.errors.full_messages.to_sentence}"
      return
    end

    lic
  end

  # saves product authors and maintainers
  def self.upsert_product_maintainer(prod_db, dev_name)
    dev_name = dev_name.to_s.strip

    dev = Developer.where(
      language: prod_db[:language],
      prod_key: prod_db[:prod_key],
      name: dev_name
    ).first_or_create

    dev.update(to_author: true)
    dev.save

    dev
  end

  #save people who manage releases
  def self.upsert_product_owner(prod_key, owner_doc)
    dev_name = owner_doc[:full_name]
    dev_name ||= owner_doc[:username]

    dev = Developer.where(
      language: A_LANGUAGE_ELIXIR,
      prod_key: prod_key,
      email: owner_doc[:email]
    ).first_or_create

    dev.update(
      name: dev_name,
      role: "owner",
      contributor: true
    )

    dev
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

  def self.fetch_product_owners(pkg_id)
    pkg_id = pkg_id.to_s.strip
    fetch_json "#{A_API_URL}/packages/#{pkg_id}/owners"
  end

  def self.fetch_product_version(pkg_id, version_label)
    pkg_id = pkg_id.to_s.strip
    fetch_json "#{A_API_URL}/packages/#{pkg_id}/releases/#{version_label}"
  end
end

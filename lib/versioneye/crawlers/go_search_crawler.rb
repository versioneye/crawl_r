class GoSearchCrawler < Versioneye::Crawl

  A_GOSEARCH_URL = 'http://go-search.org/api'
  A_MAX_WAIT_TIME      = 180

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/golang.log", 10).log
    end
    @@log
  end

  # crawls all the packages got from go-search index
  def self.crawl
    logger.info "Fetching a list of Go packages"
    all_pkgs = fetch_package_index
    if all_pkgs.to_a.empty?
      logger.error "crawl_all: failed to retrieve packages at #{A_GOSEARCH_URL}"
      return false
    end

    all_pkgs.to_a.each {|pkg_id| crawl_package(pkg_id) }
    logger.info "crawl_all: done"
    true
  end

  # fetches package details from go-search,
  def self.crawl_package( pkg_id )
    logger.info "Fetching details for #{pkg_id}"
    pkg_dt = fetch_package_detail pkg_id
    if pkg_dt.nil?
      logger.error "Failed pull package details for #{pkg_id}"
      return
    end

    prod = upsert_product(pkg_id, pkg_dt)
    create_dependencies(pkg_id, pkg_dt[:Imports], pkg_dt[:testImports])
    create_version_link(prod, pkg_dt[:projectURL])

    prod.save
    prod
  end

  def self.fetch_package_index
    fetch_json "#{A_GOSEARCH_URL}?action=packages", 180
  end

  def self.fetch_package_detail(pkg_id)
    fetch_json "#{A_GOSEARCH_URL}?action=package&id=#{pkg_id}"
  end

  # finds or creates product and updates information
  def self.upsert_product(pkg_id, pkg_dt)
    prod = Product.where(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key: pkg_id
    ).first_or_initialize

    # update github_name
    prod.update({
      name: pkg_dt[:Name],
      name_downcase: pkg_dt[:Name].to_s.downcase,
      downloads: (pkg_dt[:StarCount] + pkg_dt[:StaticRank] + 1),
      description: pkg_dt[:Synopsis],
      repo_name: to_repo_name(pkg_id)
    })

    prod.save

    prod
  end

  def self.to_repo_name(pkg_id)
    return nil if pkg_id.nil? or pkg_id.empty?

    #remove scheme and www prefix from pkg id or url
    pkg_id = pkg_id.to_s.gsub(/\Ahttps?\:\/\//i, '')
    pkg_id = pkg_id.to_s.gsub(/\Agit\:\/\//i, '')
    pkg_id = pkg_id.to_s.gsub(/\Awww\./i, '').to_s.strip

    host, owner, repo, _ = pkg_id.split('/', 4)

    "#{host}/#{owner}/#{repo}"
  end

  def self.create_dependencies(pkg_id, dependencies, test_dependencies)
    deps = []
    dependencies.to_a.each do |dep_id|
      deps << create_dependency(pkg_id, dep_id, Dependency::A_SCOPE_COMPILE)
    end

    test_dependencies.to_a.each do |dep_id|
      deps << create_dependency(pkg_id, dep_id, Dependency::A_SCOPE_DEVELOPMENT)
    end

    deps
  end

  def self.create_dependency(pkg_id, dep_id, the_scope)
    dep = Dependency.where(prod_type: Project::A_TYPE_GODEP, prod_key: pkg_id, dep_prod_key: dep_id).first
    return dep if dep

    dep = Dependency.create({
      prod_type: Project::A_TYPE_GODEP,
      language: Product::A_LANGUAGE_GO,
      prod_key: pkg_id,
      prod_version: '*',
      dep_prod_key: dep_id,
      scope: the_scope,
      version: '*'
    })

    unless dep.errors.empty?
      log.error "create_dependency: failed to save dependency #{dep_id} for #{pkg_id},\n #{dep.errors.full_messages}"
    end
    dep
  end

  def self.create_version_link(prod, url, name = "Repository")
    link = Versionlink.where(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      link: url
    ).first
    return link if link

    Versionlink.create_versionlink prod.language, prod.prod_key, nil, url, name
  end

end

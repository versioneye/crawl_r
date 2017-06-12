# GodepsGithubCrawler crawls Golang dependency files
# it tries to hit direct commit or branch url of Dependency files
# Godeps here doesn't mean the Godeps pkg-manager, but Golang deps overall
# as it tries to fetch all the Go pkg-manager which has parser

require 'versioneye/parsers/package_parser'
require 'versioneye/parsers/godep_parser'

class GodepsGithubCrawler < Versioneye::Crawl
  A_RAW_CONTENT_URL = 'https://raw.githubusercontent.com'
  A_GODEPS_PARSER = 'godeps'

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/golang.log", 10).log
    end
    @@log
  end

  # fetches project file from Github and saves dependency info from it
  # params:
  #   prod_key - String, product key of Golang package
  #   version - raw version label, it can be commit_sha, branch or tag
  # returns: boolean, for which true means it found dependencies and save them
  def self.crawl_product(prod_key, version_label)
    prod_key = prod_key.to_s.strip

    if prod_key.empty?
      log.error "crawl_product: cant work with empty product key"
      return false
    end

    repo_fullname = extract_reponame(prod_key)
    if repo_fullname.nil?
      logger.error "crawl_for_product: #{prod_key} is not valid product Github ID"
      return false
    end

    parent_product = Product.where(
      language: Product::A_LANGUAGE_GO,
      prod_key: prod_key
    ).first

    #try first to find Godeps.json file
    #TODO: refactor
    # fetch_project_file(godeps_url) ...
    proj_doc = fetch_godeps(repo_fullname, version_label)
    if proj_doc
      deps = parse_dependencies(A_GODEPS_PARSER, proj_doc)
      save_dependencies(parent_product, version_label, deps)
      return true
    end

    #TODO: add other Golang files, like govendor, glide, dep

    return false
  end

  def self.save_dependencies(parent_product, parent_version, deps)
    deps.to_a.each {|dep| save_dependency(parent_product, parent_version, dep) }
  end

  def self.save_dependency(parent_product, parent_version, dep)
    if parent_product.nil?
      log.error "save_dependency: no parent product for #{dep}"
      return false
    end

    if dep.nil?
      log.error "save_dependency: no dependency details for #{parent_product}"
      return false
    end

    log.info "save_dependency: adding #{dep} for #{parent_product} => #{parent_version}"
    dep_db = Dependency.where(
      language: parent_product[:language],
      prod_type: parent_product[:prod_type],
      prod_key: parent_product[:prod_key],
      prod_version: parent_version,
      dep_prod_key: dep[:prod_key],
      version: dep[:version_label]
    ).first_or_create

    dep_db[:name]  = dep[:name]
    dep_db[:scope] = dep[:scope]


    dep_db.save
  end

  # pulls out list of dependencies from the project file
  # returns:
  #   list of project dependencies or nil
  def self.parse_dependencies(parser_type, proj_doc)
    parser = init_parser parser_type
    if parser.nil?
      logger.error "extract_dependencies: failed to create parser for file: #{parser_type}"
      return
    end

    proj = parser.parse_content proj_doc
    if proj.nil?
      logger.error "extract_dependencies: failed to parse project document: \n #{proj_doc}"
      return
    end


    proj.projectdependencies.to_a
  rescue => e
    logger.error "extract_dependencies: failed to extract dependencies from #{proj_doc}"
    logger.error e.message
    logger.error e.backtrace.join('\n')
    nil
  end

  def self.init_parser(parser_type)
    case parser_type
    when A_GODEPS_PARSER then GodepParser.new
    else
      nil
    end
  end

  # TODO: refactor url building to support fetching files for other Parsers
  # tries to fetch Godeps file by commit_sha, branch or by tag,
  def self.fetch_godeps(repo_fullname, version_label)
    version_label = version_label.to_s.strip
    if version_label.empty?
      logger.error "fetch_godeps: no version_label for #{repo_fullname}"
      return
    end

    file_url = "#{A_RAW_CONTENT_URL}/#{repo_fullname}/#{version_label}/Godeps/Godeps.json"
    res = HTTParty.get file_url
    if res.nil? or res.code < 200 or res.code > 301
      logger.warn "fetch_godeps: found no Godeps file on #{repo_fullname}:#{version_label}"
      return
    end

    res.body
  rescue => e
    logger.error "fetch_godeps: failed to fetch Godeps dependency file for #{repo_fullname}:#{version_label}"

    logger.error e.message
    logger.error e.backtrace.join('\n')

    nil
  end

  #extract Github repo fullname from Go package id
  # returns:
  #   repo_fullname - String, returns repo fullname, i.e "versioneye/veye"
  #   nil - if failed to pull out repo and owner name or host is not on Github
  def self.extract_reponame(gopkg_id)
    host, repo, owner, _ = gopkg_id.to_s.split('/', 4)
    return 'kubernetes/kubernetes' if /k8s\.io/.match?(host) #all K8S are over url shortener

    return if /github/i.match?(host) == false
    return if repo.nil? or owner.nil?

    "#{repo}/#{owner}"
  end

end

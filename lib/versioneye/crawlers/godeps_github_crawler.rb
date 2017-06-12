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

  def self.crawl_product(prod_key, commit_sha = nil, branch = nil, tag = nil)
    repo_fullname = extract_reponame(prod_key)
    if repo_fullname.nil?
      logger.error "crawl_for_product: #{prod_key} is not valid product Github ID"
      return
    end

    proj_doc = fetch_godeps(repo_fullname, commit_sha, branch, tag)
    if proj_doc
      return extract_dependencies(A_GODEPS_PARSER, proj_doc)
    end

    #TODO: add other Golang files, like govendor, glide, dep

    return nil
  end

  # pulls out list of dependencies from the project file
  # returns:
  #   list of project dependencies or nil
  def self.extract_dependencies(parser_type, proj_doc)
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

  # tries to fetch Godeps file by commit_sha, branch or by tag,
  def self.fetch_godeps(repo_fullname, commit_sha = nil, branch = nil, tag = nil)
    commit = (commit_sha || branch || tag)
    if commit.nil?
      logger.error "fetch_godeps: no commit_sha or branch or tag specified for #{repo_fullname}"
      return
    end

    file_url = "#{A_RAW_CONTENT_URL}/#{repo_fullname}/#{commit}/Godeps/Godeps.json"
    res = HTTParty.get file_url
    if res.nil? or res.code < 200 or res.code > 301
      logger.warn "fetch_godeps: found no Godeps file on #{repo_fullname}:#{commit}"
      return
    end

    res.body
  rescue => e
    logger.error "fetch_godeps: failed to fetch Godeps dependency file for #{repo_fullname}:#{commit}"

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

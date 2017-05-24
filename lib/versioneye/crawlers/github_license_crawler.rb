class GithubLicenseCrawler < Versioneye::Crawl
  GITHUB_URL = "https://github.com"
  GITHUB_RAW_HOST = "https://raw.githubusercontent.com"

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/license.log", 10).log
    end
    @@log
  end

  # crawls all the licenses with github url and takes SPDX id from up-right corner
  def self.crawl_licenses(licenses, update = false)
    lm = LicenseMatcher.new
    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2.minutes)

    n, n_match = 0, 0
    licenses.to_a.each do |lic_db|
      n += 1
      prod_dt = {
        language: lic_db[:language],
        prod_key: lic_db[:prod_key],
        version: lic_db[:version],
        url: lic_db[:url]
      }

      res = crawl_repo_page(lm, url_cache, prod_dt, update)
      n_match += 1 if res
    end

    [n, n_match]
  end

  # crawles Licenses for each product version
  def self.crawl_product_commit_tree(language, prod_key, repo_owner, repo_name, min_confidence = 0.9, lm = nil)
    logger.info "crawl_product_commit_tree: Going to crawl licenses for #{language}/#{prod_key}"

    lm ||= LicenseMatcher.new
    prod = Product.where(language: language, prod_key: prod_key).first
    if prod.nil?
      logger.error "crawl_product_commit_tree: no such product #{language}/#{prod_key}"
      return
    end

    prod.versions.to_a.each do |version|
      prod_dt = to_prod_dt(prod, version)
      crawl_version_commit_tree(prod_dt, repo_owner, repo_name, min_confidence, lm)
    end

    logger.info "crawl_product_commit_tree: done"
  end

  #it crawls licenses from Github by using Version commit
  # params:
  #   prod_dt,   - HashMap {language: Str, prod_key: Str, version: Str, commit_sha: S}
  #   repo_owner - String, the name of repo owner, i.e versioneye
  #   repo_name - String, the name of repo, i.e versioneye-security
  #   min_confidence - float, smallest match to accept
  #   lm       - LicenseMatcher, initialization is slow, build only once
  def self.crawl_version_commit_tree(
    prod_dt, repo_owner, repo_name, min_confidence = 0.9, lm = nil
  )
    commit_sha = prod_dt[:commit_sha].to_s
    if commit_sha.empty?
      logger.error "crawl_version_commit_tree: version model has no commit_sha #{prod_dt}"
      return
    end

    commit_url = "#{GITHUB_URL}/#{repo_owner}/#{repo_name}/tree/#{commit_sha}"
    logger.info "crawl_version_commit_tree: going to check licenses from #{commit_url}"

    #fetch license file path
    license_files = fetch_licenses_from_commit_tree(commit_url)
    if license_files.nil? or license_files.empty?
      logger.error "crawl_version_commit_tree: found no licenses from #{commit_url}"
      return
    end

    #NB! it's expensive to initialize licenseMatcher for single query
    lm ||= LicenseMatcher.new
    matches = license_files.to_a.reduce([]) do |acc, lic_item|
      file_name, _ = lic_item
      raw_file_url = "#{GITHUB_RAW_HOST}/#{repo_owner}/#{repo_name}/#{commit_sha}/#{file_name}"

      #detect content
      lic_id, score = fetch_and_match_license_file(lm, raw_file_url)
      next if lic_id.nil?

      logger.info "crawl_version_commit_tree: found match #{prod_dt} #{file_name} => #{lic_id}"
      spdx_id = lm.to_spdx_id(lic_id) #license ID is normalized string
      acc << [spdx_id, score, raw_file_url]
      acc
    end


    save_license_updates(
      prod_dt, matches, min_confidence,
      "GithubLicenseCrawler.crawl_version_commit_tree"
    )

  end

  def self.crawl_versionlinks(links, update = false)
    lm = LicenseMatcher.new
    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2.minutes)
    n, n_match = 0, 0

    links.to_a.each do |link|
      n += 1
      prod_dt = {
        language: link[:language],
        prod_key: link[:prod_key],
        version: link[:version_id],
        url: link[:link]
      }

      res = crawl_repo_page(lm, url_cache, prod_dt, update)
      n_match += 1 if res
    end

    [n, n_match]
  end

  # matches spdx ids found in the div.overall-summary container on the github repo page
  def self.crawl_repo_page(lm, url_cache, prod_dt, update = false, min_confidence = 0.9)
    repo_uri = parse_url prod_dt[:url]
    return if repo_uri.nil? # ignore non-valid urls
    return if !is_github_url(repo_uri) # ignore not valid github urls

    repo_uri = to_page_url repo_uri  # unify various repo urls into main www-page url
    return if repo_uri.nil? # failed to unify repo

    lic_id, score = url_cache.fetch(repo_uri) do
      logger.info "crawl_repo_pages: going to fetch overall summary from #{repo_uri.to_s}"
      fetch_and_process_page(lm, repo_uri)
    end

    return if lic_id.nil?

    if update
      matches = [[lm.to_spdx_id(lic_id), score, repo_uri.to_s]]
      save_license_updates(prod_dt, matches, min_confidence, "GithubLicenseCrawler")
    end

    true
  end

  def self.fetch_and_process_page(lm, link_uri)
    summary_text = fetch_overall_summary link_uri

    return [] if summary_text.to_s.empty?

    best_match = lm.match_rules(summary_text).to_a.first
    if best_match.to_s.empty?
      logger.info "\tfetch_and_process_page: no license in the summary of #{link_uri.to_s}: #{summary_text}"
      return []
    end

    return best_match
  end

  #it fetches license name from the overall summary section
  def self.fetch_overall_summary(link_uri)
    res = fetch link_uri
    if res.nil? or res.code < 200 or res.code >= 400
      logger.warn "\tfetch_overall_summary: failed request #{res.code} -> #{link_uri.to_s}"
      return nil
    end

    html_doc = Nokogiri::HTML(res.body)
    return nil if html_doc.nil?

    summary_elements = html_doc.xpath('//div[contains(@class, "overall-summary")]//a').to_a
    body_text  = ""
    summary_elements.each do |el|
      if el
        #add the `license` string to lower ambiguity as we are matching very specific area on the page
        body_text += ' ' + el.text.to_s + ' license '
      end
    end

    body_text.gsub(/\s+/, ' ')
  end


  #extracts urls of license files from file list of the commit
  # params:
  #   commit_url - url to the file list on the commit tree,
  #   for example: https://github.com/serde-rs/serde/tree/fd3d1396d33a49200daaaf8bf17eba78fe4183d8
  #   returns list of tuples [ fileName, filePath ]
  def self.fetch_licenses_from_commit_tree(commit_url)
    res = fetch commit_url
    if res.nil? or res.code < 200 or res.code >= 400
      logger.warn "\tfetch_licenses_from_commit_tree: faild request #{res.code} -> #{commit_url.to_s}"
      return nil
    end

    html_doc = Nokogiri::HTML(res.body)
    file_items = html_doc.xpath(
      '//table[contains(@class, "files")]/tbody/tr/td[contains(@class, "content")]/span/a'
    ).to_a

    # extract license files by their names
    file_items.to_a.reduce([]) do |acc, el|
      filename = el['title'].to_s.strip
      url = el['href'].to_s

      if is_license_filename(filename)
        logger.info "\tfetch_licenses_from_commit_tree: found #{filename} : #{url}"
        acc << [ filename, url ]
      end

      acc
    end
  end

  # tries to read and match license file content with SPDX files
  # returns [spdx_id, confidence] if there's match otherwise nil
  def self.fetch_and_match_license_file(lm, file_url)
    res = fetch file_url
    if res.nil? or res.code < 200 or res.code > 400
      logger.error "fetch_and_match_license_file: got no response #{file_url.to_s}"
      return
    end

    matches = lm.match_text res.body
    return matches.to_a.first
  end

  def self.is_license_filename(filename)
    case filename.to_s
    when /li[c|s|z]en[c|s]e/i
      true
    when /copyright/i
      true
    else
      false
    end
  end

  def self.is_github_url(uri)
    false if uri.to_s.empty?

    if uri.host =~ /github\.com\z/i or uri.host =~ /githubusercontent\.com\z/i
      true
    else
      false
    end
  end

  def self.to_prod_dt(product, version)
    {
      language: product[:language],
      prod_key: product[:prod_key],
      version: version[:version],
      commit_sha: version[:commit_sha]
    }
  end

  # unifies various github urls into repo main-page
  def self.to_page_url(link_uri)
    _, owner, repo, _ = link_uri.path.to_s.split(/\//)
    return nil if owner.nil? or repo.nil?

    parse_url("#{GITHUB_URL}/#{owner}/#{repo}")
  end


end

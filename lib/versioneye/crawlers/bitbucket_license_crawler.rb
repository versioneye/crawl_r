class BitbucketLicenseCrawler < Versioneye::Crawl
  A_HOST_URL = "https://bitbucket.org"

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/license.log", 10).log
    end
    @@log
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

  #it crawls licenses from Bitbucket by using Version commit
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

    commit_url = "#{A_HOST_URL}/#{repo_owner}/#{repo_name}/src/#{commit_sha}"
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
      raw_file_url = "#{A_HOST_URL}/#{repo_owner}/#{repo_name}/raw/#{commit_sha}/#{file_name}"

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
      "BitbucketLicenseCrawler.crawl_version_commit_tree"
    )

  end



  #extracts urls of license files from file list of the commit
  # params:
  #   commit_url - url to the file list on the commit tree,
  #   for example:
  #     https://bitbucket.org/mchaput/whoosh/src/20f2c538262e8f656e089521a21a9fa5c8ae3394
  #   returns list of tuples [ fileName, filePath ]
  def self.fetch_licenses_from_commit_tree(commit_url)
    res = fetch commit_url
    if res.nil? or res.code < 200 or res.code >= 400
      logger.warn "\tfetch_licenses_from_commit_tree: faild request #{res.code} -> #{commit_url.to_s}"
      return nil
    end

    url_sel = '//table[@id="source-list"]/tbody/tr/td[contains(@class, "filename")]/div/a'
    html_doc = Nokogiri::HTML(res.body)
    file_items = html_doc.xpath(url_sel).to_a

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

  def self.to_prod_dt(product, version)
    {
      language: product[:language],
      prod_key: product[:prod_key],
      version: version[:version],
      commit_sha: version[:commit_sha]
    }
  end
end

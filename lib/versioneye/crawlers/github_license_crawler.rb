class GithubLicenseCrawler < Versioneye::Crawl
  GITHUB_URL = "https://github.com"


  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/license.log", 10).log
    end
    @@log
  end

  def self.is_github_url(uri)
    false if uri.to_s.empty?

    if uri.host =~ /github\.com\z/i or uri.host =~ /githubusercontent\.com\z/i
      true
    else
      false
    end
  end


  # unifies various github urls into repo main-page
  def self.to_page_url(link_uri)
    _, owner, repo, _ = link_uri.path.to_s.split(/\//)
    return nil if owner.nil? or repo.nil?

    parse_url("#{GITHUB_URL}/#{owner}/#{repo}")
  end

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

end

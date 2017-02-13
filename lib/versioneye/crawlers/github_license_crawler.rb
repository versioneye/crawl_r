class GithubLicenseCrawler < Versioneye::Crawl
  GITHUB_URL = "https://github.com"

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/license.log", 10).log
    end
    @@log
  end


  def self.fetch url
     HTTParty.get url, { timeout: 5 }
  rescue
    logger.error "failed to fetch data from #{url}"
    {code: 500}
  end

  def self.parse_url url_text
    uri = URI.parse(url_text)
    
    return uri if uri.is_a?(URI::HTTPS) or uri.is_a?(URI::HTTP)
    return nil
  rescue
    logger.error "Not valid url: #{url_text}"
    nil
  end


  def self.is_github_url(uri)
    false if uri.to_s.empty?

    if uri.host =~ /github\.com\z/i or uri.host =~ /githubusercontent\.com\z/i
      true
    else
      false
    end
  end

  #unifies various github urls into repo main-page
  def self.to_page_url(link_uri)
    _, owner, repo, _ = link_uri.path.to_s.split(/\//)
    return nil if owner.nil? or repo.nil?
    page_url = parse_url("#{GITHUB_URL}/#{owner}/#{repo}")
    logger.info "\t to_page_url: #{link_uri.to_s} => #{page_url.to_s}"
    page_url
  end

  # matches spdx ids div.overall-summary containes on the github repo page
  def self.crawl_repo_pages(licenses, update = false)
    lm = LicenseMatcher.new
    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2.minutes)

    n, matched = 0, 0
    licenses.to_a.each do |lic_db|
      link_uri = parse_url lic_db[:url]
      next if link_uri.nil? # ignore non-valid urls
      next if !is_github_url(link_uri) # ignore not valid github urls
      link_uri = to_page_url link_uri  # unify various repo urls into main www-page url
      next if link_uri.nil? # failed to unify repo

      lic_id, score = url_cache.fetch(link_uri) do
        logger.info "crawl_repo_pages: going to fetch overall summary from #{link_uri.to_s}"
        fetch_and_process_page(lm, link_uri)
      end

      n += 1
      next if lic_id.nil?
        
      if update
        lic_db[:spdx_id] = lm.to_spdx_id(lic_id)
        lic_db[:comments] = "github_license_crawler.crawl_repo_pages"
        lic_db.save

        logger.debug "\t-- updated #{lic_db.to_s} spdx_id -> #{lic_db[:spdx_id]}"
      else
        logger.debug "\t-- matched #{lic_db.to_s} spdx_id -> #{lic_id}"
      end

      matched += 1
    end

    logger.info "crawl_repo_pages: done. crawled #{n} github pages, found match #{matched}"
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
    if res.code < 200 or res.code >= 400
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

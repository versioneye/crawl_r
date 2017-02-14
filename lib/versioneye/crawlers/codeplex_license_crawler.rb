class CodeplexLicenseCrawler < Versioneye::Crawl

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/license.log", 10).log
    end
    @@log
  end

  # filters out codeplex licenses and tries to match content of license page
  def self.crawl_pages(licenses, min_confidence = 0.9, update = false)
    lm = LicenseMatcher.new
    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2.minutes)

    n, matched = 0,0
    licenses.to_a.each do |lic_db|
      link_uri = parse_url lic_db[:url]
      next if link_uri.nil? #ignore non-valid urls
      next unless is_codeplex_url(link_uri)

      lic_uri = to_license_url(link_uri)
      next if lic_uri.nil?

      lic_id, score = url_cache.fetch(lic_uri) do
        logger.info "crawl_pages: going to fetch codeplex license from #{lic_uri.to_s}"
        fetch_and_process_page(lm, lic_uri)
      end

      n += 1
      next if lic_id.nil?
      if score < min_confidence
        logger.warn "\t-- too low confidence for #{lic_uri.to_s} => #{lic_id}, #{score}"
        next
      end

      #when it found great match with existing SPDX licenses
      matched += 1
      if update
        lic_db.spdx_id  = lm.to_spdx_id(lic_id)
        lic_db.comments = "codeplex_license_crawler.crawl_pages"
        lic_db.save
        logger.debug "\t-- updated #{lic_db.to_s} -> #{lic_db.spdx_id}"
      else
        logger.debug "\t-- matched #{lic_db.to_s} -> #{lic_id} : #{score}"
      end

    end

    logger.info "crawl_pages: done. crawled #{n} pages, fount match #{matched}"
  end

  def self.fetch_and_process_page(lm, lic_uri)
    res = fetch lic_uri
    if res.nil? or res.code < 200 or res.code >= 400
      logger.warn "\tfetch_and_process_page: failed to fetch #{lic_uri.to_s}"
      return []
    end
 
    txt = lm.preprocess_text lm.preprocess_html res.body.to_s
    txt_results = lm.match_text txt
    rlz_results = lm.match_rules txt
    #shortcut if txt matches with 'custom license'
    return ['custom', 1.0] if rlz_results.one? {|x| x[0].downcase == 'custom' }
   
    if rlz_results.size > 1
      logger.warn "\trule_matcher has too many matches: #{lic_uri.to_s} -> #{rlz_results}"
    end

    #otherwise combine text and rules results
    ranked_results = lm.rank_text_and_rules_matches(txt_results, rlz_results)

    ranked_results.to_a.first
  end

  def self.to_license_url(uri)
    if uri.is_a? String
      uri = parse_url uri
    end
    
    return nil if uri.nil? or uri.to_s.empty?
    parse_url "https://#{uri.host}/license"
  end

  def self.is_codeplex_url(uri)

    if uri.is_a? String
      uri = parse_url uri
    end
    
    return false if uri.nil? or uri.to_s.empty?
    return true if uri.host =~ /codeplex\.com\z/i
    false
  end

end

class CodeplexLicenseCrawler < Versioneye::Crawl

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/license.log", 10).log
    end
    @@log
  end

  # filters out codeplex licenses and tries to match content of license page
  def self.crawl_licenses(licenses, update = false,  min_confidence = 0.9)
    return [0,0] if licenses.to_a.empty?

    lm = LicenseMatcher.new
    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2.minutes)

    n, n_matched = 0,0
    licenses.to_a.each do |lic_db|
      n += 1
      prod_dt = {
        language: lic_db[:language],
        prod_key: lic_db[:prod_key],
        version: lic_db[:version],
        url: lic_db[:url]
      }

      res = crawl_license_page(lm, url_cache, prod_dt, update, min_confidence)
      n_matched += 1 if res
    end

    [n, n_matched]
  end

  def self.crawl_links(links, update = false, min_confidence = 0.9)
    return [0, 0] if links.to_a.empty?

    lm = LicenseMatcher.new
    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2.minutes)

    n, n_matched = 0,0
    links.to_a.each do |link|
      n += 1
      prod_dt = {
        language: link[:language],
        prod_key: link[:prod_key],
        version: link[:version_id],
        url: link[:link]
      }

      res = crawl_license_page(lm, url_cache, prod_dt, update, min_confidence)
      n_matched += 1 if res
    end

    [n, n_matched]
  end


  def self.crawl_license_page(lm, url_cache, prod_dt, update, min_confidence)
    link_uri = parse_url prod_dt[:url]
    return if link_uri.nil? #ignore non-valid urls
    return unless is_codeplex_url(link_uri)

    lic_uri = to_license_url(link_uri)
    return if lic_uri.nil?

    lic_id, score = url_cache.fetch(lic_uri) do
      logger.info "crawl_license_page: going to fetch codeplex license from #{lic_uri.to_s}"
      fetch_and_process_page(lm, lic_uri)
    end
    return if lic_id.nil?

    logger.info "crawl_license_page: match #{prod_dt} => #{lic_id} : #{score} , #{lic_uri.to_s}"

    if update
      matches = [[lm.to_spdx_id(lic_id), score, lic_uri.to_s]]
      save_license_updates(prod_dt, matches, min_confidence, "CodeplexLicenseCrawler")
    end

    true
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

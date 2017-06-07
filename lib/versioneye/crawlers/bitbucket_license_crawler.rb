require 'nokogiri'

class BitbucketLicenseCrawler < Versioneye::Crawl
  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/license.log", 10).log
    end
    @@log
  end
  def self.crawl_moved_pages(licenses, update = false)
    return if licenses.nil? or licenses.empty?

    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2.minutes)

    n, n_moved = [0, 0]
    licenses.to_a.each do |lic_db|
      n += 1

      lic_uri = to_repo_url lic_db[:url]
      next if lic_uri.nil?
      
      code, new_url = url_cache.fetch(lic_uri) do
        logger.info "crawl_moved_pages: fetching #{lic_uri.to_s}"
        fetch_and_process_moved_page(lic_uri)
      end
      
      next if code != 404 or new_url.nil?
  
      n_moved += 1
      if update == true
        logger.info "updated url #{lic_db.to_s} => #{new_url}"
        old_url = lic_db[:url].to_s
        lic_db[:url] = new_url.to_s
        lic_db[:comments] = "BitbucketCrawler::crawl_moved_pages: old url #{old_url}"
        lic_db.save
      else
        logger.info "found new url #{lic_db.to_s} => #{new_url}"
      end
    end

    [n, n_moved]
  end

  #crawls licenses with bitbucket urls and tries to find license-file from it
  def self.crawl_licenses(licenses, update = false, min_confidence = 0.9)
    lm = LicenseMatcher.new
    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2.minutes)

    n, n_match = [0, 0]
    licenses.to_a.each do |lic_db|
      n += 1
      prod_dt = {
        language: lic_db[:language],
        prod_key: lic_db[:prod_key],
        version: lic_db[:version],
        url: lic_db[:url]
      }

      res = crawl_repo_licenses(lm, url_cache, prod_dt, update, min_confidence)
      n_match += 1 if res
    end

    [n, n_match]
  end

  def self.crawl_version_links(links, update = false, min_confidence = 0.9)
    lm = LicenseMatcher.new
    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2.minutes)

    n, n_match = [0,0]
    links.to_a.each do |link_db|
      n += 1
      prod_dt = {
        language: link_db[:language],
        prod_key: link_db[:prod_key],
        version: link_db[:version_id],
        url: link_db[:link]
      }

      res = crawl_repo_licenses(lm, url_cache, prod_dt, update, min_confidence)
      n_match += 1 if res
    end

    [n, n_match]
  end

  #crawls license files from Bitbucket site
  #prod_dt = hash-map {:language String, :prod_key String, :version String, :url String}
  def self.crawl_repo_licenses(lm, url_cache, prod_dt, update, min_confidence)
    repo_uri = to_repo_url prod_dt[:url]
    return unless is_bitbucket_url(repo_uri)

    code, file_urls = url_cache.fetch(repo_uri) do
      logger.info "Trying to find license file from #{repo_uri.to_s}"  
      fetch_license_urls( repo_uri.to_s )
    end
    
    if code != 200
      logger.info "Failed to request data from #{code} => #{repo_uri.to_s}"
      return
    end
    
    if file_urls.to_a.empty?
      logger.info "Found no license file at #{repo_uri}"
      return
    end

    logger.info "Found #{prod_dt.to_s} license files: \n\t #{file_urls}"
    matches = []
    file_urls.to_a.each do |file_url|
      lic_id, score = url_cache.fetch(file_url) do
        fetch_and_match_license_file(lm, file_url)
      end
      
      if lic_id
        matches << [lm.to_spdx_id(lic_id), score, file_url]

        logger.info "\tMatch #{file_url} => #{lic_id} : #{score} "
      else
        logger.info "\tNo match #{file_url}"
      end

    end

    return if matches.empty?

    if update
      save_license_updates(prod_dt, matches, min_confidence)
    end
    true
  end
  
#-- helper functions
 
  #TODO: what if multiple licenses??
  def self.save_license_updates(prod, matches, min_confidence)
    return false if matches.nil?

    matches.to_a.each do |spdx_id, score, url|
      if score < min_confidence
        logger.warn "update_license_data: low confidence #{score} < #{min_confidence}"
        logger.warn "license #{prod.to_s} , #{spdx_id}, #{url}"
        next
      end
      
      logger.info "save_license_updates: upsert a versionLicense #{prod} => #{spdx_id} : #{score}"
      upsert_license_data(
        prod[:language], prod[:prod_key], prod[:version], spdx_id, url,
        "BitbucketLicenseCrawler.crawl_licenses"
      )
 
    end

    true
  end

  def self.upsert_license_data(language, prod_key, version, spdx_id, url, comments = "")
    prod_licenses = License.where(language: language, prod_key: prod_key, version: version)
    lic_db = prod_licenses.where(name: 'Nuget Unknown').first #try to update unknown license
    lic_db = prod_licenses.where(spdx_id: spdx_id).first unless lic_db #try to upate existing
    lic_db = prod_licenses.first_or_create unless lic_db #create a new model if no matches
    
    lic_db.update(
      name: spdx_id,
      spdx_id: spdx_id,
      url: url,
      comments: comments
    )
    lic_db.save
    lic_db
  end

  #tries to read and match license file content with SPDX files
  #returns [spdx_id, confidence] if there's match otherwise nil
  def self.fetch_and_match_license_file(lm, file_url)
    res = fetch file_url
    if res.nil? or res.code < 200 or res.code > 400
      logger.error "fetch_and_match_license_file: got no response #{file_url.to_s}"
      return
    end

    matches = lm.match_text res.body
    return matches.to_a.first
  end


  #tries to find license file from the repo's source listing
  #returns [status_code, urls]
  def self.fetch_license_urls(repo_uri)
    res = fetch "#{repo_uri.to_s}/src" 
    return [500, nil] if res.nil?
    return [res.code, nil] if res.code < 200 or res.code > 400

    urls = extract_license_file_urls res.body

    return [res.code, urls]
  end

  def self.fetch_and_process_moved_page(repo_uri)
    res = fetch repo_uri
    return [500, nil]      if res.nil?
    return [res.code, nil] if res.code < 200 or res.code > 404
    return [res.code, nil] if res.code != 404

    new_url = extract_moved_url res.body
    if new_url.nil?
      return [res.code, nil]
    end

    return [res.code, new_url]
  end

  def self.extract_moved_url(html_txt)
    html_txt = html_txt.to_s.gsub(/\s+/, ' ').strip
    return if html_txt.to_s.empty?

    html_doc = Nokogiri::HTML(html_txt)
    return if html_doc.nil?

    elems = html_doc.xpath('//section[@id="repo-unavialable"]//a').to_a
    return if elems.nil?

    url = nil
    elems.each {|el| url = el[:href] if el.has_attribute?('href') }

    url
  end

  def self.extract_license_file_urls(html_txt)
    html_txt = html_txt.to_s.gsub(/\s+/, ' ').strip
    return if html_txt.to_s.empty?

    html_doc = Nokogiri::HTML(html_txt)
    return if html_doc.nil?

    elems = html_doc.xpath(
      '//table[@id="source-list"]//td[contains(@class, "filename")]//a'
    )

    host = "https://bitbucket.org"
    elems.to_a.reduce([]) do |acc, el|
      if is_license_file( el[:title] )
        acc << host.to_s + el[:href].to_s.gsub(/\/src\//, '/raw/')
      end

      acc
    end

  end

  def self.is_license_file(filename)
    filename = filename.to_s.strip
    return false if filename.empty?
    return true if filename =~ /LICEN[S|C]E/i
    return true if filename =~ /\ACOPYING/i
    return false
  end

  def self.is_bitbucket_url(uri)
    uri = parse_url(uri) if uri.is_a?(String)
    return false if uri.nil?

    return true if uri.host =~ /bitbucket\.org/
    return false
  end

  def self.to_repo_url(uri)
    uri = parse_url(uri) if uri.is_a?(String)
    return if uri.nil?

    _, owner, repo, _ = uri.path.split(/\//)
    parse_url "https://#{uri.host}/#{owner}/#{repo}"
  end


end

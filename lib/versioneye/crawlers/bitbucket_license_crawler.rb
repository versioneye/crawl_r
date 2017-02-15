require 'nokogiri'

class BitbucketLicenseCrawler < Versioneye::Crawl
  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/license.log", 10).log
    end
    @@log
  end

  def self.to_repo_url(uri)
    uri = parse_url(uri) if uri.is_a?(String)
    return if uri.nil?

    _, owner, repo, _ = uri.path.split(/\//)
    parse_url "https://#{uri.host}/#{owner}/#{repo}"
  end

  def self.crawl_moved_pages(licenses, update = false)
    return if licenses.nil? or licenses.empty?

    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2.minutes)

    n, n_moved = [0, 0]
    licenses.to_a.each do |lic_db|
      n += 1

      lic_uri = BitbucketLicenseCrawler.to_repo_url lic_db[:url]
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

  def self.fetch_and_process_moved_page(repo_uri)
    res = fetch repo_uri
    return [500, nil]      if res.nil?
    return [res.code, nil] if res.code < 200 or res.code > 404
    return [res.code, nil] if res.code != 404

    new_url = BitbucketLicenseCrawler.extract_moved_url res.body
    if new_url.nil?
      return [res.code, nil]
    end

    return [res.code, new_url]
  end

  def self.extract_moved_url(html_txt)
    return if html_txt.to_s.empty?
    html_txt = html_txt.to_s.gsub(/\s+/, ' ').strip

    html_doc = Nokogiri::HTML(html_txt)
    return if html_doc.nil?

    elems = html_doc.xpath('//section[@id="repo-unavialable"]//a').to_a
    return if elems.nil?

    url = nil
    elems.each {|el| url = el[:href] if el.has_attribute?('href') }

    url
  end


end

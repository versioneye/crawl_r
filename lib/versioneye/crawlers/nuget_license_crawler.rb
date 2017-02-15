class NugetLicenseCrawler < Versioneye::Crawl

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/license.log", 10).log
    end
    @@log
  end

  def self.to_nuget_page_url(pkg_id, pkg_version)
    #parse_url "https://www.nuget.org/packages/#{pkg_id}/#{pkg_version}"
    parse_url "https://www.nuget.org/packages/#{pkg_id}"
  end

  #fetches license info from the nuget page of the package license
  def self.crawl_licenses(licenses, update = false)
    return if licenses.nil? or licenses.empty?

    url_cache = ActiveSupport::Cache::MemoryStore.new(expires_in: 2)

    n, n_lic = [0, 0]
    licenses.to_a.each do |lic_db|
      n += 1
      
      lic_uri = to_nuget_page_url(lic_db[:prod_key], lic_db[:version])
      lic_id = url_cache.fetch(lic_uri) do
        logger.info "crawl_licenses: fetching #{lic_uri.to_s}"
        fetch_and_process_nuget_page(lic_uri)
      end

      if lic_id.nil?
        logger.warn "crawl_licenses: no license information on #{lic_uri.to_s}"
        next
      end

      n_lic += 1
      if update == true
        lic_db[:spdx_id]  = lic_id
        lic_db[:comments] = "NugetLicenseCrawler.crawl_licenses"
        lic_db.save

        logger.info "crawl_licenses: updated #{lic_db.to_s} => #{lic_id}"
      else
        logger.info "crawl_licenses: found #{lic_db.to_s} => #{lic_id}"
      end
    end

    [n, n_lic]
  end


  def self.fetch_and_process_nuget_page(page_uri)
    res = fetch page_uri
    return if res.nil?
  
    if res.code < 200 or res.code > 400
      logger.error "fetch_and_process_nuget_page: no response from #{page_uri.to_s}"
      return
    end

    extract_sonatype_license res.body
  end


  def self.extract_sonatype_license(html_txt)
    return if html_txt.to_s.empty?
    html_txt = html_txt.to_s.gsub(/\s+/, ' ').strip

    html_doc = Nokogiri::HTML(html_txt)
    return if html_doc.nil?

    elems = html_doc.xpath('//div[contains(@class, "block")]//p[contains(@class, "licenseName")]').to_a

    return if elems.nil? or elems.empty?
    elems.first.text
  end
end

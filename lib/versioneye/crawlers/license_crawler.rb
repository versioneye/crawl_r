class LicenseCrawler < Versioneye::Crawl


  A_SOURCE_GMB = 'GMB' # GitHub Master Branch


  def self.logger
    ActiveSupport::BufferedLogger.new('log/license.log')
  end


  def self.crawl
    links_uniq = []
    links = Versionlink.where(:link => /http.+github\.com\/\w*\/\w*[\/]*$/i)
    logger.info "found #{links.count} github links"
    links.each do |link|
      next if links_uniq.include?(link.link)
      links_uniq << link.link

      product = fetch_product link
      next if product.nil?

      # This step is temporary for the init crawl
      licenses = product.licenses true
      next if licenses && !licenses.empty?

      process link, product
    end
    logger.info "found #{links_uniq.count} unique  github links"
  end


  def self.process link, product
    repo_name = link.link
    repo_name = repo_name.gsub(/\?.*/i, "")
    repo_name = repo_name.gsub(/http.+github\.com\//i, "")
    sps = repo_name.split("/")
    if sps.count > 2
      logger.info " - SKIP #{repo_name}"
      return
    end

    process_github_master repo_name, product
  end


  def self.process_github_master repo_name, product
    licens_forms = ['LICENSE', 'MIT-LICENSE', 'LICENSE.md', 'LICENSE.txt']
    licens_forms.each do |lf|
      raw_url = "https://raw.githubusercontent.com/#{repo_name}/master/#{lf}"
      license_found = process_url raw_url, product
      return true if license_found
    end
    false
  end


  def self.process_url raw_url, product
    resp = HttpService.fetch_response raw_url
    return false if resp.code.to_i != 200

    lic_info = recognize_license resp.body, raw_url, product
    return false if lic_info.nil?
    return true
  end


  def self.recognize_license content, raw_url, product
    if is_mit?( content )
      logger.info " -- MIT found at #{raw_url} --- "
      find_or_create( product, 'MIT', raw_url )
      return 'MIT'
    end

    if is_apache_20?( content ) || is_apache_20_short?( content )
      logger.info " -- Apache License 2.0 found at #{raw_url} --- "
      find_or_create( product, 'Apache License 2.0', raw_url )
      return 'LGPL-3.0'
    end

    if is_bsd?( content )
      logger.info " -- BSD found at #{raw_url} --- "
      find_or_create( product, 'BSD', raw_url )
      return 'BSD'
    end

    if is_gpl_30?( content )
      logger.info " -- GPL-3.0 found at #{raw_url} --- "
      find_or_create( product, 'GPL-3.0', raw_url )
      return 'GPL-3.0'
    end

    if is_lgpl_30?( content )
      logger.info " -- LGPL-3.0 found at #{raw_url} --- "
      find_or_create( product, 'LGPL-3.0', raw_url )
      return 'LGPL-3.0'
    end

    logger.info " -- NOT RECOGNIZED at #{raw_url} -- "
    nil
  end


  private


    def self.find_or_create product, name, url
      License.find_or_create_by({:language => product.language, :prod_key => product.prod_key,
        :version => nil, :name => name, :url => url, :source => A_SOURCE_GMB })
    end


    def self.fetch_product link
      product = link.product
      return product if product

      if link.language.eql?("Java")
        product = Product.fetch_product "Clojure", link.prod_key
      end
      ensure_language(link, product)

      link.remove if product.nil?

      product
    end


    def self.ensure_language link, product
      return true if product.nil?
      return true if product.language.eql?(link.language)

      link.language = product.language
      link.save
    rescue => e
      p e.message
      logger.info "DELETE #{link.to_s}"
      link.remove
      false
    end


    def self.is_mit? content
      content = prepare_content content
      content = content.gsub("'", "\"")
      content = content.gsub("`", "\"")
      content = content.gsub("‘", "\"")

      return false if content.match(/Permission is hereby granted, free of charge, to any person obtaining/i).nil?
      return false if content.match(/a copy of this software and associated documentation files/i).nil?
      return false if content.match(/to deal in the Software without restriction, including/i).nil?

      return false if content.match(/THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND/i).nil?
      return false if content.match(/EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF/i).nil?
      return false if content.match(/MERCHANTABILITY, FITNESS FOR A PARTICULAR PURP/i).nil?
      return false if content.match(/LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION/i).nil?
      return false if content.match(/OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION/i).nil?
      return false if content.match(/WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE./i).nil?

      return true
    end


    def self.is_apache_20? content
      content = prepare_content content
      return false if content.match(/Apache License Version 2.0/i).nil?
      return false if content.match(/TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION/i).nil?
      return false if content.match(/shall mean the terms and conditions for use, reproduction, and distribution as defined by Sections 1 through 9 of this document/i).nil?
      return true
    end

    def self.is_apache_20_short? content
      content = prepare_content content
      return false if content.match(/http\:\/\/www\.apache\.org\/licenses\/LICENSE-2\.0/i).nil?
      return false if content.match(/Licensed under the Apache License, Version 2.0/i).nil?
      return true
    end


    def self.is_gpl_30? content
      content = prepare_content content

      return false if content.match(/GNU GENERAL PUBLIC LICENSE/i).nil?
      return false if content.match(/Version 3/i).nil?
      return false if content.match(/The GNU General Public License is a free, copyleft license for/i).nil?
      return false if content.match(/"This License" refers to version 3 of the GNU General Public License/i).nil?

      return true
    end


    def self.is_lgpl_30? content
      content = prepare_content content

      return false if content.match(/GNU LESSER GENERAL PUBLIC LICENSE/i).nil?
      return false if content.match(/Version 3/i).nil?
      return false if content.match(/the GNU Lesser General Public License incorporates the terms and conditions of version 3 of the GNU General Public License/i).nil?

      return true
    end


    def self.is_bsd? content
      content = prepare_content content

      return false if content.match(/is distributed under the BSD license/i).nil?
      return false if content.match(/Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met/i).nil?
      return false if content.match(/THIS SOFTWARE IS PROVIDED BY THE AUTHOR/i).nil?

      return true
    end


    def self.prepare_content content
      content = content.gsub(/\n/, " ")
      content = content.gsub(/\r/, " ")
      content = content.gsub(/\s+/, " ")
      content
    end


end

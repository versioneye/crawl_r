class LicenseCrawler < Versioneye::Crawl


  def self.logger
    ActiveSupport::BufferedLogger.new('log/license.log')
  end


  def self.crawl
    links_uniq = []
    links = Versionlink.where(:link => /http.+github\.com\/\w*\/\w*[\/]*$/xi)
    p "found #{links.count} github links"
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
    p "found #{links_uniq.count} unique  github links"
  end


  def self.process link, product
    p "process #{link.link}"
    repo_name = link.link
    repo_name = repo_name.gsub(/\?.*/xi, "")
    repo_name = repo_name.gsub(/http.+github\.com\//xi, "")
    sps = repo_name.split("/")
    if sps.count > 2
      p " - SKIP #{repo_name}"
      return
    end

    p " - repo_name: #{repo_name}"

    licens_forms = ['LICENSE', 'MIT-LICENSE', 'LICENSE.md', 'LICENSE.txt']
    licens_forms.each do |lf|
      raw_url = "https://raw.githubusercontent.com/#{repo_name}/master/#{lf}"
      found = handle_url raw_url, product
      return if found
    end

    p "No License found for #{repo_name} :-( "
  end


  def self.handle_url raw_url, product
    resp = HttpService.fetch_response raw_url
    return false if resp.code.to_i != 200

    p " -- found license at #{raw_url}"
    p " -- "
    # TODO process
    return true
  end


  private


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
      p "DELETE #{link.to_s}"
      link.remove
      false
    end


end

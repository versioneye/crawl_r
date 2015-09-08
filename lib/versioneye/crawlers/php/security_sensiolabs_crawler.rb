class SecuritySensiolabsCrawler


  def self.logger
    ActiveSupport::Logger.new('log/security_sensiolabs.log')
  end


  def self.crawl
    start_time = Time.now
    lis = self.get_first_level_list
    lis.each do |li|
      self.crawle_package li
    end
    duration = Time.now - start_time
    self.logger.info(" *** This crawl took #{duration} *** ")
    return nil
  end


  def self.get_first_level_list
    url = "https://security.sensiolabs.org/database.html"
    page = Nokogiri::HTML(open(url))
    page.xpath("//ul/li")
  end


  def self.crawle_package li_node
    return nil if li_node.to_s.empty?

    prod_key = fetch_prod_key li_node
    link_names = fetch_link_names li_node
    sv = fetch_sv prod_key, link_names

    if sv.nil?
      logger.info "sv is nil for #{li_node}"
      return nil
    end

    li_node.children.each do |child|
      process_links child, sv
      process_affected_versions child, sv
    end
    sv.save if !sv.affected_versions_string.to_s.empty?
  rescue => e
    self.logger.error "ERROR in crawle_package Message: #{e.message}"
    self.logger.error e.backtrace.join("\n")
  end


  def self.process_links child, sv
    return nil if !child.name.eql?('a') || child['href'].to_s.strip.match(/https\:\/\/packagist\.org/) || child['href'].eql?('/')

    title = child.text.to_s.strip
    if !sv.links.include?( title )
      sv.links[title] = child['href'].strip
    end
    sv.cve = title if title.to_s.match(/\Acve/i)
    sv.summary = title if sv.summary.to_s.empty?
  end


  def self.process_affected_versions child, sv
    return nil if !child.text.to_s.strip.match(/Affected versions/i)

    text = child.text.to_s.strip
    sv.affected_versions_string = text

    matches = text.scan(/\[(.*?)\]/xi)
    return nil if matches.nil? || matches.size == 0

    product = sv.product
    if product.nil?
      self.logger.info "no product for #{sv.prod_key}"
      return nil
    end

    mark_affected_versions sv, matches
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  def self.mark_affected_versions sv, matches
    product = sv.product
    affected_string = ''
    matches.each do |version_range|
      affected_string += version_range.to_s
      versions = VersionService.from_ranges product.versions, version_range.first
      versions.each do |version|
        next if version.to_s.match(/\Adev\-/)
        next if sv.affected_versions.include?(version.to_s)

        sv.affected_versions.push(version.to_s)

        product.reload
        v_db = product.version_by_number version.to_s
        if !v_db.sv_ids.include?(sv._id.to_s)
          v_db.sv_ids << sv._id.to_s
          v_db.save
        end
      end
    end
    sv.affected_versions_string = affected_string
  end


  def self.fetch_sv prod_key, link_names
    return nil if link_names.to_a.empty?

    svs = SecurityVulnerability.by_language( Product::A_LANGUAGE_PHP ).by_prod_key( prod_key )
    svs.each do |sv|
      if sv
        link_names.each do |link_name|
          return sv if sv.summary.to_s.eql?(link_name)
        end
      end
    end

    self.logger.info "Create new SecurityVulnerability for #{Product::A_LANGUAGE_PHP}:#{prod_key} - #{link_names.first}"
    SecurityVulnerability.new(:language => Product::A_LANGUAGE_PHP, :prod_key => prod_key, :summary => link_names.first )
  end


  def self.fetch_link_names li_node
    titles = []
    li_node.children.each do |child|
      next if !child.name.eql?('a') || child['href'].to_s.strip.match(/https\:\/\/packagist\.org/) || child['href'].eql?('/')

      titles << child.text.to_s.strip
    end
    titles
  end


  def self.fetch_prod_key li_node
    li_node.children.each do |child|
      if child.name.eql?('a') && child['href'].to_s.strip.match(/https\:\/\/packagist\.org/)
        return child.text.strip.downcase
      end
    end
    nil
  rescue => e
    self.logger.error "ERROR in fetch_packagist_name Message: #{e.message}"
    self.logger.error e.backtrace.join("\n")
    nil
  end

end

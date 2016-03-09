class BranchCleaner

  def self.clean
    ProductService.all_products_paged do |products|
      products.each do |product|
        next if !product.language.eql?("PHP")
        clean_product product
      end
    end
  end

  def self.clean_product product
    product.versions.each do |version|
      version_number = version.to_s
      link = Versionlink.where( language: "PHP", prod_key: product.prod_key, version_id: version.to_s, name: "Source", link: /github\.com/ ).first
      next if link.nil?

      raw_url = "#{link}/releases/tag/#{version_number}"
      resp = HttpService.fetch_response raw_url
      next if resp.code.to_i == 200

      if version_number.to_s.match(/^v/)
        version_number.gsub!(/^v/, '')
      else
        version_number = "v#{version_number}"
      end

      raw_url = "#{link}/releases/tag/#{version_number}"
      resp = HttpService.fetch_response raw_url
      next if resp.code.to_i == 200

      p "#{product.prod_key} - #{version.to_s} is not a tag!"
      product.remove_version version.to_s
    end
  rescue => e
    p e.message
    p e.backtrace.join("\n")
  end

end

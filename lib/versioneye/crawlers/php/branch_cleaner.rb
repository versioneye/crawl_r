class BranchCleaner 

  def self.clean 
    products = Product.where(:language => "PHP")
    products.each do |product|
      clean_product product
    end
  end

  def self.clean_product product 
    product.versions.each do |version| 
      product.version = version.to_s 
      is_branch1 = PackagistCrawler.is_branch? product, "v#{version.to_s}" 
      is_branch2 = PackagistCrawler.is_branch? product, version.to_s
      next if is_branch1 == false || is_branch2 == false 

      p "#{product.prod_key} - #{version.to_s} is a branch!"
      product.remove_version version.to_s 
    end
  end

end
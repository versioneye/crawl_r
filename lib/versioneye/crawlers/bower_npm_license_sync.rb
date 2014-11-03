class BowerNpmLicenseSync


  # It checks if there is a corresponding NPM package with licenses
  # if so it copies the license info to the bower package.
  def self.sync
    count = 0
    Product.where(:prod_type => "Bower").each do |prod|
      next if prod.licenses && !prod.licenses.empty?

      np = Product.where(:language => "Node.JS", :prod_key => prod.name).first
      next if np.nil?

      names = License.where(:language => np.language, :prod_key => np.prod_key).distinct(:name)
      next if names.empty?

      p "#{np.prod_key} - #{names} - #{prod.versions.count}"
      if prod.versions.empty? || prod.versions.count == 1
        p "-- case 1"
        licenses = License.where(:language => np.language, :prod_key => np.prod_key)
        licenses.each do |license|
          License.find_or_create_by({:language => prod.language, :prod_key => prod.prod_key,
            :version => nil, :name => license.name, :url => license.url, :source => "NPM" })
        end
      else
        p "-- case 2"
        prod.versions.each do |ver|
          licenses = License.where(:language => np.language, :prod_key => np.prod_key, :version => ver.to_s)
          next if licenses.nil? || licenses.empty?

          licenses.each do |license|
            License.find_or_create_by({:language => prod.language, :prod_key => prod.prod_key,
              :version => ver.to_s, :name => license.name, :url => license.url, :source => "NPM" })
          end
        end
      end

      count += 1
    end
    p count
  end


end

require 'httparty'

class SpdxCrawler
  DEFAULT_LICENSE_FILES_PATH = 'data/spdx_licenses/plain'
  SPDX_URI = "https://spdx.org/licenses/"  

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/license.log", 10).log
    end
    @@log
  end

  def self.crawl(crawl_license_texts = false)
    p "map = {}"
    map = {}
    page = Nokogiri::HTML(open(SPDX_URI))
    trs = page.xpath("//table[contains(@class,'sortable')]/tbody/tr")
    trs.each do |tr|
      handle_line tr, map
    end
    p "map"

    if crawl_license_texts
      logger.info "Going to save license texts to #{DEFAULT_LICENSE_FILES_PATH}"
      crawl_license_files(map.keys, DEFAULT_LICENSE_FILES_PATH)
    end

    map
  end

  def self.crawl_license_files(spdx_ids, target_folder)
    #spdx list contains license files with same content as parent
    #aka cross-checking each file gives conflicting 1.0 scores with other
    blacklist = Set.new [
      'bsd-3-clause-attribution', 'mpl-2.0-no-copyleft-exception', 
      'bsd-4-clause-uc', 'oldap-2.2.2'
    ]

    spdx_ids.each do |spdx_id|
      lic_url = "#{SPDX_URI}#{spdx_id}.txt"
      res = HTTParty.get(lic_url)

      spdx_id = spdx_id.to_s.strip.downcase
      next if blacklist.include? spdx_id #duplicate licenses

      spdx_id = spdx_id.gsub(/-clause/, '') #unify BSD licenses with ids in licenses.json
     
      if res.code == 200
        logger.info "crawl_license_files: going to save #{spdx_id} license text"
        File.open("#{target_folder}/#{spdx_id}", 'w') do |file|
          txt = safe_encode(res.body)
          txt = txt.gsub(/\<\<var.+?\>\>/i, ' ') #replace template vars
          file.write(txt)
        end
      else
        logger.error "Failed to pull license text from the #{lic_url}"  
      end
    end
  end

  def self.safe_encode(txt)
    txt.to_s.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  rescue
    log.error "Failed to encode text:\n #{txt}i"
    return ""
  end


  def self.handle_line tr, map
    full_name = ''
    identifier = ''
    approved = false
    row = 0
    tr.children.each do |td|
      next if !td.name.eql?('td')

      full_name = handle_full_name(td) if row == 0
      identifier = handle_identifier(td) if row == 1
      if row == 2
        approved = true if td.text.strip.eql?('Y')
      end

      row += 1
    end

    p "map['#{identifier}'] = {:fullname => '#{full_name}', :osi_approved => #{approved}}"
    map[identifier] = {:fullname => full_name, :osi_approved => approved}
    map
  end


  def self.handle_full_name td
    td.children.each do |child|
      next if !child.name.eql?("a")
      return child.text
    end
    nil
  end


  def self.handle_identifier td
    td.children.each do |child|
      next if !child.name.eql?('code')
      return child.text
    end
    nil
  end


end

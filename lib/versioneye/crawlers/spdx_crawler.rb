class SpdxCrawler


  def self.crawl
    p "map = {}"
    map = {}
    url = "https://spdx.org/licenses/"
    page = Nokogiri::HTML(open(url))
    trs = page.xpath("//table[contains(@class,'sortable')]/tbody/tr")
    trs.each do |tr|
      handle_line tr, map
    end
    p "map"
    map
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

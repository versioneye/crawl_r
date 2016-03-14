
# https://hub.docker.com/v2/repositories/reiz/
# https://hub.docker.com/v2/repositories/reiz/mongodb/
# https://hub.docker.com/v2/repositories/reiz/mongodb/tags/

class DockerCrawler < Versioneye::Crawl

  include HTTParty


  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/docker.log", 10).log
    end
    @@log
  end


  def self.crawl
    resources = self.get_first_level_list
    logger.info "#{resources.count} resources to crawle"
    p "#{resources.count} resources to crawle"
    resources.each do |resource|
      crawle_package resource
    end
    return nil
  end


  def self.get_first_level_list
    list = []
    n = 1
    while 1 == 1
      image_exists = false
      doc = Nokogiri::HTML( open("https://hub.docker.com/explore/?page=#{n}") )
      doc.xpath("//a").each do |link|
        if link['href'].match(/\A\/_\/.*/)
          name = link['href'].gsub(/\A\/_\//, '').gsub("/", "")
          list << name
          p name
          image_exists = true
        end
      end
      if image_exists
        n += 1
      else
        return list
      end
    end
    list
  end


  def self.crawle_package name
    resource = "https://hub.docker.com/v2/repositories/#{name}/"
    p "fetch #{resource}"
    image = JSON.parse HTTParty.get( resource ).response.body
    p image
    p "---"
  rescue => e
    self.logger.error "ERROR in crawle_package(#{name}) Message: #{e.message}"
    self.logger.error e.backtrace.join("\n")
    nil
  end

end

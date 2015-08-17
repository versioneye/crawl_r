class CrawlerUtils


  def self.create_newest( product, version_number, logger = nil )
    NewestService.create_newest( product, version_number, logger )
  rescue => e
    logger.error "ERROR in create_notifications - Message: #{e.message}"
    logger.error e.backtrace.join("\n")
    nil
  end


  def self.create_notifications(product, version_number, logger = nil)
    NewestService.create_notifications(product, version_number, logger)
  rescue => e
    logger.error "ERROR in create_notifications - Message: #{e.message}"
    logger.error e.backtrace.join("\n")
    nil
  end


  def self.remove_version_prefix version_number
    if version_number && version_number.match(/\Av[0-9]+\..*/)
      version_number.gsub!(/\Av/, '')
    end
    if version_number && version_number.match(/r[0-9]+\..*/)
      version_number.gsub!('r', '')
    end
    if version_number && version_number.match(/php\-[0-9]+\..*/)
      version_number.gsub!('php-', '')
    end
    if version_number && version_number.match(/PHP\_[0-9]+\..*/)
      version_number.gsub!('PHP_', '')
    end
    version_number
  end


end

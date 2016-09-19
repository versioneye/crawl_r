class CrawlerUtils

  #splits dual-licensed license string to separate licenses
  def self.split_licenses(licenses_obj)
    if licenses_obj.is_a?(Array)
      licenses_obj.map(&:strip)
    elsif licenses_obj.is_a?(String) and licenses_obj.first == '(' and licenses_obj.last == ')'
      licenses_obj.gsub(/\(|\)/, '').gsub(/\s+or\s+/i, ',').split(',').to_a
    elsif licenses_obj.is_a?(String)
      [licenses_obj]
    else
      [] #happens only if spec of composer.json has been changed
    end
  end

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
    if version_number && version_number.match(/php\-[0-9]+\..*/i)
      version_number.gsub!('php-', '')
    end
    if version_number && version_number.match(/PHP\_[0-9]+\..*/i)
      version_number.gsub!('PHP_', '')
    end
    if version_number && version_number.match(/nw\-[0-9]+\..*/i)
      version_number.gsub!('nw-', '')
    end
    if version_number && version_number.match(/nw\-v[0-9]+\..*/i)
      version_number.gsub!('nw-v', '')
    end
    if version_number && version_number.match(/release\-v[0-9]+\..*/i)
      version_number.gsub!('release-', '')
    end
    if version_number && version_number.match(/release\-[0-9]+\..*/i)
      version_number.gsub!('release-', '')
    end
    version_number
  end


end

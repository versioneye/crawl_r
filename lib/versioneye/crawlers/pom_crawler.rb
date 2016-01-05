class PomCrawler < NpmCrawler


  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/poms.log", 10).log
    end
    @@log
  end


  def self.crawl pom_dir = '/Users/reiz/Library/Android/sdk/'
    i = 0
    all_pom_files( pom_dir ) do |filepath|
      i += 1
      p "Parse pom file ##{i}: #{filepath}"
      parse_pom filepath
    end
  end


  # traverse directory, search for .pom files
  def self.all_pom_files(dir, &block)
    Dir.glob "#{dir}/**/*.pom" do |filepath|
      block.call filepath
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  def self.parse_pom( filepath )
    file = File.open(filepath, "rb")
    file_con = file.read
    file.close

    project = PomParser.new.parse_content( file_con )

    product = Product.find_or_create_by(
      :language => project.language,
      :group_id => project.group_id.downcase,
      :artifact_id => project.artifact_id.downcase)

    update_product project, product
    process_deps project, product
    process_licenses project, product, file_con
    product.add_repository "http://developer.android.com/sdk/index.html"
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  def self.process_licenses project, product, file_con
    doc = PomParser.new.fetch_xml file_con
    doc.xpath('//licenses/license').each do |node|
      license = License.find_or_create_by(:language => product.language,
                            :prod_key => product.prod_key,
                            :version => project.version)
      node.children.each do |child|
        if child.name.casecmp('name') == 0
          license.name = child.text.strip
        elsif child.name.casecmp('url') == 0
          license.url = child.text.strip
        elsif child.name.casecmp('distribution') == 0
          license.distributions = child.text.strip
        end
      end
      if !license.name.to_s.empty?
        license.save
      end
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  def self.update_product project, product
    product.prod_type        = project.project_type
    product.prod_key         = "#{product.group_id}/#{product.artifact_id}"
    product.group_id_orig    = project.group_id
    product.artifact_id_orig = project.artifact_id
    product.name             = project.artifact_id
    product.description      = project.description if !product.description.to_s.empty?
    product.description_manual = "See http://developer.android.com/sdk/index.html"
    product.version          = project.version     if !product.version.to_s.empty?
    product.add_version project.version
    saved = product.save
    saved
  end


  def self.process_deps project, product
    project.projectdependencies.each do |proj_dep|
      process_dep project, product, proj_dep
    end
  end


  def self.process_dep project, product, proj_dep
    dep = Dependency.find_or_create_by(
      :language     => project.language,
      :prod_key     => product.prod_key,
      :prod_version => project.version,
      :dep_prod_key => proj_dep.prod_key,
      :version      => proj_dep.version_label,
      :scope        => proj_dep.scope
    )
    dep.name            = proj_dep.name
    dep.group_id        = proj_dep.group_id,
    dep.artifact_id     = proj_dep.artifact_id,
    dep.current_version = proj_dep.version_current
    dep.parsed_version  = proj_dep.version_requested
    dep.known           = proj_dep.known?
    dep.outdated        = proj_dep.outdated
    dep.save
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


end


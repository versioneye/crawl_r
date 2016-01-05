class CoreosCrawler < Versioneye::Crawl


  include HTTParty


  def self.logger
    ActiveSupport::Logger.new('log/coreos.log', 10, 2048000)
  end


  def self.crawl
    resources = self.get_first_level_list
    logger.info "#{resources.count} resources to crawle for CoreOS"
    resources.each do |resource|
      crawle_package resource
    end
    nil
  end


  def self.get_first_level_list
    JSON.parse HTTParty.get('https://coreos.com/releases/releases.json' ).response.body
  end


  def self.crawle_package resource
    logger.info "crawl #{resource.first}"
    product = fetch_product

    version = resource.first
    infos   = resource.last
    release_date = parse_date infos["release_date"]
    product.add_version version, {:released_string => infos["release_date"], :released_at => release_date}

    license = License.find_or_create_by(:language => product.language, :prod_key => product.prod_key, :version => version)
    license.name = "CoreOS Open Source Licenses"
    license.url = "https://coreos.com/legal/open-source/"
    license.save

    docker = infos["major_software"]["docker"].join(",")
    kernel = infos["major_software"]["kernel"].join(",")
    etcd   = infos["major_software"]["etcd"].join(",")
    fleet  = infos["major_software"]["fleet"].join(",")

    markdown_string = "**Major Software** \n\n - **Kernel:** #{kernel} \n - **Docker:** #{docker} \n - **Etcd:** #{etcd} \n - **fleet:** #{fleet} \n\n"
    rnotes = infos["release_notes"]
    notes = "#{markdown_string} #{rnotes}"

    change_entry = ScmChangelogEntry.find_or_create_by(:language => product.language, :prod_key => product.prod_key, :version => version)
    change_entry.change_date = release_date
    change_entry.message = notes
    change_entry.message_md = true
    change_entry.save
  rescue => e
    self.logger.error "ERROR in crawle_package(#{resource}) Message: #{e.message}"
    self.logger.error e.backtrace.join("\n")
    nil
  end


  def self.fetch_product
    product = Product.find_or_create_by(
      :language => Product::A_LANGUAGE_GO,
      :prod_key => 'coreos' )
    product.prod_type = Project::A_TYPE_GITHUB
    product.name = 'CoreOS'
    product.name_downcase = 'coreos'
    product.tags = ['coreos', 'linux']
    product.description = "CoreOS creates and maintains open source projects for Linux Containers. CoreOS is an open-source lightweight operating system based on the Linux kernel and designed for providing infrastructure to clustered deployments, while focusing on automation, ease of applications deployment, security, reliability and scalability. As an operating system, CoreOS provides only the minimal functionality required for deploying applications inside software containers, together with built-in mechanisms for service discovery and configuration sharing."

    Versionlink.find_or_create_by(:language => product.language, :prod_key => product.prod_key, :link => "https://github.com/coreos", :name => "GitHub")
    Versionlink.find_or_create_by(:language => product.language, :prod_key => product.prod_key, :link => "https://coreos.com/", :name => "Homepage")
    Versionlink.find_or_create_by(:language => product.language, :prod_key => product.prod_key, :link => "https://github.com/coreos/bugs/issues/", :name => "Ticket System")

    product
  end


  def self.parse_date string_date
    DateTime.parse string_date
  rescue => e
    nil
  end


end
require 'pqueue'

class GodepCrawler < Versioneye::Crawl

  A_GODEP_REGISTRY_URL = 'http://go-search.org/api'

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/godep.log", 10).log
    end
    @@log
  end

  def self.crawl_all
    pkg_queue = PQueue.new([]) {|x,y| x[:rank] > y[:rank]}

    all_pkgs = fetch_package_index
    if all_pkgs.to_a.empty?
      log.error "crawl: failed to retrieve packages for #{A_GODEP_REGISTRY_URL}"
      return
    end

    pkg_id = all_pkgs.first
    pkg_dt = crawl_package( pkg_id )
    if pkg_dt.nil?
      log.error "crawl: failed to retrieve package details for #{pkg_id}"
      return
    end

    pkg_queue
  end

  def self.crawl_package(pkg_id)
    pkg_dt = fetch_package_detail pkg_id
    if pkg_dt.nil?
      log.error "Failed pull package details for #{pkg_id}"
      return
    end

    res = clone_repo pkg_id
    p "#-- clone res: #{res}"

    versions = process_cloned_repo pkg_id
    p "#-- processed version tree: ", versions
    pkg_dt
  end


  def self.fetch_package_index
    fetch_json "#{A_GODEP_REGISTRY_URL}?action=packages"
  end

  def self.fetch_package_detail(pkg_id)
    content = fetch_json "#{A_GODEP_REGISTRY_URL}?action=package&id=#{pkg_id}"
    return if content.nil?
    
    process_package_details(pkg_id, content)
  end

  def self.clone_repo(pkg_id)
   res = system("git clone https://#{pkg_id}.git tmp/#{pkg_id}")

   p "#-- clone-repo: ", res
   res
  end

  def self.process_package_details(pkg_id, pkg_dt)
    {
      prod_id: pkg_id,
      name: pkg_dt[:name],
      prod_type: 'Godeps',
      language: 'Go',
      rank: (pkg_dt[:StarCount] + pkg_dt[:StaticRank] + 1),
      description: pkg_dt[:Description],
      url: pkg_dt[:ProjectURL],
      dependencies: pkg_dt[:Imports],
      test_dependencies: pkg_dt[:TestImports]
    }
  end

  def self.process_cloned_repo(pkg_id)
    working_dir = Dir.pwd
    system("cd tmp/#{pkg_id}")
    commit_versions = []

    begin
      commit_versions = build_commit_version_index(pkg_id)
    rescue
      log.error "process_cloned_repo: Failed to build commit version index"
    ensure
      system(working_dir)
      #system("rm -rf tmp/#{pkg_id}")
    end

    commit_versions
  end

  def self.build_commit_version_tree(pkg_id)
    commit_idx = {}

    commit_idx
  end

  def self.read_commit_logs(pkg_id)
    skip = 0
    max_count = 50
    while true
      page = %x["git log --pretty --format='%H;%ct;%P;'%s' --skip=#{skip} --max-count=#{max_count}"]
      break if page.nil?
      
      p "#-- Page:", page
      skip += max_count
    end
  end

  def self.fetch_json( url )
    res = HTTParty.get(url)
    if res.code != 200
      self.logger.error "Failed to fetch JSON doc from: #{url} - #{res}"
      return nil
    end
    JSON.parse(res.body, {symbolize_names: true})
  end


end

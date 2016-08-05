require 'timeout'

class GodepCrawler < Versioneye::Crawl

  A_GODEP_REGISTRY_URL = 'http://go-search.org/api'
  A_TYPE_GODEP         = 'Godep'
  A_LANGUAGE_GO        = 'Go'
  A_MAX_QUEUE_SIZE     = 500
  A_MAX_WAIT_TIME      = 180

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/godep.log", 10).log
    end
    @@log
  end

  def self.crawl_all
    clone_queue   = Queue.new
    indexer_queue = Queue.new
    save_queue    = Queue.new
    

    all_pkgs = fetch_package_index
    if all_pkgs.to_a.empty?
      logger.error "crawl: failed to retrieve packages for #{A_GODEP_REGISTRY_URL}"
      return
    end

    tasks = []
    tasks << run_persistor_worker(save_queue)
    tasks << run_clone_worker(clone_queue, indexer_queue)
    tasks << run_clone_worker(clone_queue, indexer_queue)
    tasks << run_clone_worker(clone_queue, indexer_queue)

    tasks << run_git_indexer(indexer_queue, save_queue)
    tasks << run_detail_worker(all_pkgs.take(5000), clone_queue)
 
    tasks.each {|t| t.join}
    
    log.info "crawl_all: done"
    true
  end

  def self.run_detail_worker(pkg_queue, result_queue)
    Thread.new do
      pkg_queue.each do |pkg_id|
        logger.info "run_detail_worker: going to fetch meta-info for #{pkg_id}"

        prod = Timeout::timeout(A_MAX_WAIT_TIME) { crawl_package(pkg_id) }
        if prod.nil?
          logger.error "crawl_packages: failed to read packages data for: #{pkg_id}"
          next
        end

        #force small break so cloner could catch it up
        if result_queue.size > A_MAX_QUEUE_SIZE
          logger.info "run_detail_worker: taking a little break;"
          sleep(5) 
        end

        result_queue.push prod
        sleep(1)
      end

      logger.info "run_detail_worker: done"
      result_queue.push :done
    end

  end

  def self.run_clone_worker(product_queue, result_queue)
    Thread.new do
      logger.info "run_clone_worker: listening"
      while ( the_prod = product_queue.pop) != :done
        if the_prod.nil?
          sleep(1)
          next
        end

        pkg_id = the_prod[:prod_key]
        logger.info "run_clone_worker: going to clone #{pkg_id}"

        result = Timeout::timeout(A_MAX_WAIT_TIME) { clone_repo(pkg_id, the_prod[:group_id]) }
        if result == true
          result_queue.push the_prod
        end
      end

      logger.info "run_clone_worker: done"
      result_queue.push :done
    end
  end

  def self.run_git_indexer(product_queue, result_queue)
    Thread.new do
      logger.info "run_git_indexer: listening"
      while (the_prod = product_queue.pop ) != :done
        if the_prod.nil?
          sleep 1
          next
        end

        pkg_id = the_prod[:prod_key]
        logger.info "run_git_indexer: indexing #{pkg_id}"

        versions = Timeout::timeout(A_MAX_WAIT_TIME) { process_cloned_repo(pkg_id) }
        if versions.nil?
          logger.error "crawl_all: failed to read commit logs for #{pkg_id}"
          next
        end

        the_prod.versions = versions #NB: it replaces old versions;
        latest = VersionService.newest_version(versions)
        if latest
          the_prod[:version] = latest.version
        end
        
        result_queue.push the_prod
        sleep 1
      end

      logger.info "run_git_indexer: done"
      result_queue.push :done
    end
  end

  def self.run_persistor_worker(product_queue)
    Thread.new do
      logger.info "run_persistor_worker: listening"

      while (the_prod = product_queue.pop) != :done
        if the_prod.nil?
          sleep(1)
          next
        end

        pkg_id = the_prod[:prod_key]
        logger.info "run_persistor_worker: saving #{pkg_id}"
        the_prod.save
      end

      logger.info "run_persistor_worker: done"
    end
  end


  #fetches package details from go-search, 
  def self.crawl_package(pkg_id)
    pkg_dt = fetch_package_detail pkg_id
    if pkg_dt.nil?
      logger.error "Failed pull package details for #{pkg_id}"
      return
    end


    prod = init_product(pkg_id, pkg_dt)
    create_dependencies(pkg_id, pkg_dt[:Imports], pkg_dt[:testImports])
    create_version_link(prod, pkg_dt[:projectURL])

    prod.save
    prod
  end

  def self.fetch_package_index
    fetch_json "#{A_GODEP_REGISTRY_URL}?action=packages"
  end

  def self.fetch_package_detail(pkg_id)
    fetch_json "#{A_GODEP_REGISTRY_URL}?action=package&id=#{pkg_id}"
  end

  def self.clone_repo(pkg_id, pkg_url)
    system("git clone #{pkg_url} tmp/#{pkg_id}")
  rescue => e
    logger.error "failed to clone the repo: #{pkg_id} - #{pkg_url}"
    logger.error e.backtrace.join('\n')
    return nil
  end

  def self.process_cloned_repo(pkg_id)
    logger.info "process_cloned_repo: reading repo logs for #{pkg_id}"
    repo_idx = GitVersionIndex.new("tmp/#{pkg_id}")
    repo_idx.build       #builds version tree from commit logs
    repo_idx.to_versions #transforms version tree into list of Version models
  rescue
    logger.error "process_cloned_repo: Failed to build commit version index"
    return nil
  ensure
    system("rm -rf tmp/#{pkg_id}")
  end


  def self.init_product(pkg_id, pkg_dt)
    prod = Product.where(language: A_LANGUAGE_GO, prod_type: A_TYPE_GODEP, prod_key: pkg_id).first
    return prod if prod

    Product.create({
      prod_key: pkg_id,
      name: pkg_dt[:name],
      name_downcase: pkg_dt[:name].to_s.downcase,
      prod_type: A_TYPE_GODEP,
      language: A_LANGUAGE_GO,
      downloads: (pkg_dt[:StarCount] + pkg_dt[:StaticRank] + 1), #TODO: add rank field for the Product model
      description: pkg_dt[:Description],
      group_id: pkg_dt[:ProjectURL] #one repo may include many GOdep packages ~ AWS stuff and used for passing urls to cloning process
    })
  end

  def self.create_dependencies(pkg_id, dependencies, test_dependencies)
    deps = []
    dependencies.to_a.each {|dep_id| deps << create_dependency(pkg_id, dep_id, Dependency::A_SCOPE_COMPILE) }
    test_dependencies.to_a.each {|dep_id| deps << create_dependency(pkg_id, dep_id, Dependency::A_SCOPE_DEVELOPMENT) }

    deps
  end

  def self.create_dependency(pkg_id, dep_id, the_scope)
    dep = Dependency.where(prod_type: A_TYPE_GODEP, prod_key: pkg_id, dep_prod_key: dep_id).first
    return dep if dep

    Dependency.create({
      prod_type: A_TYPE_GODEP,
      language: A_LANGUAGE_GO,
      prod_key: pkg_id,
      prod_version: '*', #no idea until we process 
      dep_prod_key: dep_id,
      scope: the_scope,
      version: '*'
    })
  end

  def self.create_version_link(prod, url, name = "Repository")
    link = Versionlink.where(language: A_LANGUAGE_GO, prod_type: A_TYPE_GODEP, name: name).first
    return link if link

    Versionlink.create_versionlink prod.language, prod.prod_key, nil, url, name
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

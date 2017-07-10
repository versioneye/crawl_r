require 'semverly'

class GithubVersionCrawler < Versioneye::Crawl

  include HTTParty


  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/github_version_crawler.log", 10).log
    end
    @@log
  end


  # Crawle Release dates for Objective-C packages
  def self.crawl(language = Product::A_LANGUAGE_OBJECTIVEC, empty_release_dates = true, desc = true )
    products(language, empty_release_dates, desc).each do |product|
      add_version_to_product( product )
    end
  end


  # pulls and updates product versions from Github tags
  # params:
  #   api_client - initialized GithubVersionFetcher with own auth keys
  #   product    - Product model to update
  #   repo_owner - string, the name of github account
  #   repo_name  - string, the name of github repo
  def self.crawl_for_product(api_client, product, repo_owner, repo_name)
    if api_client.check_limit_or_pause == 0
      logger.error "crawl_for_product: hit ratelimit #{repo_owner}/#{repo_name} for #{product}"
      return
    end

    # fetch repo tags and attach commit dates
    tags = api_client.fetch_all_repo_tags(repo_owner, repo_name)
    tags = attach_commit_date(api_client, repo_owner, repo_name, tags)

    # save product versions
    tags.to_a.each do |tag|
      upsert_product_version(product, tag)
      # TODO check license. RR or TG.
    end

    if product.save
      product.reload
      ProductService.update_version_data( product )

      logger.info "crawl_for_product: #{product} has now #{product.versions.size} version"
      true
    else
      logger.error "crawl_for_product: failed to save updated #{product}"
      logger.error "  reason: #{product.errors.full_messages.to_sentence}"
      false
    end
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    false
  end


  # It fetches and attaches commit date for each Tag
  # Tags api doesnt return commit date
  def self.attach_commit_date(api_client, repo_owner, repo_name, tags)
    tags.to_a.map do |tag|
      tag_date = fetch_tag_commit_date(
        api_client, repo_owner, repo_name, tag[:commit][:sha]
      )

      if tag_date
        tag[:created_at] = tag_date
      else
        logger.error "crawl_for_product: failed to crawl all the commit dates for #{repo_owner}/#{repo_name}"
      end
    end

    tags
  end

  def self.fetch_tag_commit_date(api_client, repo_owner, repo_name, commit_sha)
    if api_client.check_limit_or_pause == 0
      logger.error "crawl_tag_commit_date: hit ratelimit for #{repo_owner}/#{repo_name} - #{commit_sha}"
      return
    end

    logger.info "crawl_tag_commit_date:  fetching commit date for #{repo_owner}/#{repo_name}:#{commit_sha}"
    commit_details = api_client.fetch_commit_details(repo_owner, repo_name, commit_sha)
    return if commit_details.nil?


    commit_details[:commit][:committer][:date]
  end

  # processes Tag and updates/inserts Product version
  # NB! it saves only valid SEMVER versions
  #
  # params:
  #   tag - Hashmap with response from Github tags endpoint
  #         expected structure: {name: String, created_at: String, commit: {:sha}}
  def self.upsert_product_version(product, tag)
    semver_label = process_version_label( tag[:name] )
    if semver_label.to_s.empty?
      logger.warn "upsert_product_version: ignoring non-valid semver #{tag[:name]} for #{product.prod_key}"
      return nil
    end

    if !product.version_by_number( tag[:name] ).nil?
      logger.warn "Version #{tag[:name]} for #{product.prod_key} exist already."
      return nil
    end

    ver = product.versions.where(version: semver_label).first_or_initialize
    ver.update(
      tag: tag[:name],
      status: 'stable',
      released_at: tag[:created_at],
      released_string: tag[:created_at].to_s,
      commit_sha: tag[:commit][:sha].to_s
    )

    ver
  end

  def self.process_version_label(label)
    label = label.to_s.gsub(/\s+/, '').to_s.strip

    semver = SemVer.parse(label)
    return "" if semver.nil?
    semver.to_s
  end

  #--- old stuff waiting for refactoring

  def self.products( language, empty_release_dates, desc = true )
    products = Mongoid::Criteria.new(Product)
    qparams = { :prod_type => Project::A_TYPE_COCOAPODS, :language => language }
    if empty_release_dates
      qparams['versions.released_at'] = nil
    end

    products = Product.where(qparams)
    products = if desc
                products.desc(:name)
               else
                products.asc(:name)
               end

    products.no_timeout
  end


  def self.add_version_to_product ( product )
    repo = git_repo_src( product )
    return nil if repo.to_s.empty?
    return nil if repo.to_s.eql?('https://github.com/CocoaPods/Specs')

    github_versions = versions_for_github_url( repo )
    return nil if github_versions.nil? || github_versions.empty?

    update_release_dates product, github_versions
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
  end


  def self.git_repo_src product
    product.repositories.each do |repo|
      return repo.src if /#{Settings.instance.github_base_url}\/(.+)\/(.+)\.git/.match repo.src
    end
    return nil
  end


  def self.update_release_dates( product, github_versions )
    # update releases infos at version
    product.versions.each do |version|
      v_hash = version_hash github_versions, version.to_s
      next if v_hash.nil? || v_hash.empty?

      version.released_at     = v_hash[:released_at]
      version.released_string = v_hash[:released_string]
      product.save
      logger.info "update #{product.name} v #{version} was released at #{version.released_at}"
    end
    remaining = OctokitApi.client.ratelimit.remaining
    if remaining < 60
      logger.info "Remaining API requests: #{remaining} - Going to sleep for a while!"
      sleep 60 # sleep a minute!
    else
      logger.info "check version dates for #{product.prod_key} - Remaining API requests: #{remaining}"
    end
  end


  def self.version_hash github_versions, version_string
    version_hash = github_versions[version_string]
    if version_hash.nil? || version_hash.empty?
      # couldn't find 0.0.1, try v0.0.1
      version_hash = github_versions["v#{version_string}"]
      if version_hash.nil? || version_hash.empty?
        return
      end
    end
    version_hash
  end


  def self.versions_for_github_url github_url
    versions   = {}
    owner_repo = parse_github_url github_url
    return nil if owner_repo.nil? || owner_repo.empty?

    owner     = owner_repo[:owner]
    repo      = owner_repo[:repo]
    tags_data = GithubVersionFetcher.new().fetch_all_repo_tags(owner, repo)
    return nil if tags_data.nil? || tags_data.empty?

    tags_data.each do |tag|
      process_tag( versions, tag, owner_repo )
    end
    versions
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end


  def self.process_tag(versions, tag, owner_repo )
    v_name      = tag.name
    sha         = tag.commit.sha
    date_string = fetch_commit_date( owner_repo, sha )
    return nil if date_string.to_s.empty?

    date_time   = DateTime.parse date_string
    versions[v_name] = {
      :sha             => sha,
      :released_at     => date_time,
      :released_string => date_string,
    }
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end

  # NB! deprecated - it doesnt allow use it to crawl user data or switch keys
  def self.fetch_commit_date( owner_repo, sha )
    return nil unless owner_repo
    api = OctokitApi.client
    commit = api.commit(owner_repo, sha)
    return commit[:commit][:committer][:date].to_s
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end


  def self.repo_data owner_repo, api = nil
    api  ||= OctokitApi.client

    root = api.root
    root.rels[:repository].get(:uri => owner_repo).data
  end


  def self.parse_github_url (git_url)
    match = /#{Settings.instance.github_base_url}\/(.+)\/(.+)\.git/.match git_url
    owner_repo = {:owner => $1, :repo => $2}
    if match.nil? || match == false
      logger.error "Couldn't parse #{git_url}"
      return nil
    end
    owner_repo
  rescue => e
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end

end

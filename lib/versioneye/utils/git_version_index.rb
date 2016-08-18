require 'rugged'
require 'csv'

#builds version index from git logs
class GitVersionIndex
  attr_reader :dir, :tree
  
  A_DEFAULT_VERSION = '0.0.0'

  def initialize(repo_path, logger = nil)
    unless Dir.exist?(repo_path)
      raise "GitVersionIndex: Folder doesnt exist: `#{repo_path}`"
    end

    @logger = logger
    @logger ||= Versioneye::DynLog.new('log/godep.log', 10).log
    @dir = Dir.new repo_path
    @repo = Rugged::Repository.new(repo_path)

    @tree = {}
    @tag_sha_idx = {}
    @sha_tag_idx = {}
  end

  def build
    @logger.info "git_version_index: building index"
    latest_sha = get_latest_sha()
    first_sha = get_earliest_sha(latest_sha)

    tag_idx = get_tags
    @tag_sha_idx = {A_DEFAULT_VERSION => first_sha, 'head' => latest_sha}.merge tag_idx
    @sha_tag_idx = @tag_sha_idx.invert

    init_tree(@tag_sha_idx)
    walk_commits( latest_sha ) # processes all the logs from the beginning to end

    @tree
  end

  def init_tree(tag_shas)
    tag_shas.each_pair do |tag, sha|
      @tree[tag] = {
        label: tag,
        start_sha: sha,
        shas: Set.new([ sha ]), #used to check up tags
        commits: [] #used to convert to Version models for a product/project
      }
    end

    @tree
  end

  # read licenses from commit
  def get_license_files_from_sha(commit_sha)
    repo_idx = @repo.index
    tree = @repo.lookup(commit_sha).tree
    return if tree.nil?
    
    repo_idx.read_tree(tree)
    #filter out license files
    file_names = tree.to_a.reduce([]) do |acc, f|
      acc << f if ( f[:name] =~ /\Alicense/i )
      acc
    end

    #read content
    file_names.reduce([]) do |acc, f|
      blob = @repo.lookup f[:oid]
      if blob
        acc << {
          name: f[:name],
          oid: f[:oid],
          content: blob.content
        }
      end

      acc
    end
  end

  #walks over commits and attach them parent tags' version
  def walk_commits(start_sha, end_sha = nil)
    walker = init_commit_walker(start_sha, end_sha)

    walker.each do |commit_obj|
      commit = process_commit_log(commit_obj)
      commit_tag = find_latest_parent_tag(@tree, commit)
      
      #add tag into tag commit index 
      if commit_tag
        @tree[commit_tag][:shas] << commit[:sha]
        @tree[commit_tag][:commits] << commit
      end

    end

    @tree
  end

  def init_commit_walker(start_sha, end_sha)
    walker = Rugged::Walker.new( @repo )
    walker.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)
    walker.push start_sha
    walker.hide(end_sha) if end_sha

    walker
  end

  def process_commit_log(commit_obj)
    {
      sha: commit_obj.oid,
      commited_at: commit_obj.committer[:time],
      message: commit_obj.message,
      parents: commit_obj.parents.map(&:oid)
    } 
  end

  #finds latest tag by it's parents
  def find_latest_parent_tag(tag_tree, the_commit)
    parent_tags = []

    #find tags where the commit sha or its' parent shas belong
    tag_tree.each_pair do |tag, tag_doc|
      checkable_shas = [the_commit[:sha]] + the_commit[:parents].to_a 
      matching_shas = tag_doc[:shas].intersection(checkable_shas)
      parent_tags << tag unless matching_shas.empty?
    end

    if parent_tags.size == 1
      parent_tags.first
    elsif parent_tags.size >= 2
      #if it's merge of branches, then take the maximum tag

      Naturalsorter::Sorter.sort_version(parent_tags).last
    else
      #those commits are probably from untagged and never merged branches
      @logger.warn "find_latest_parent_tag: found no matching tag for the sha #{the_commit[:sha]}"
      A_DEFAULT_VERSION
    end
  end

  def get_tags
    @repo.tags.reduce({}) do |acc, tag|
      acc[tag.name] = tag.target.oid
      acc
    end
  end

  def get_earliest_sha(latest_sha)
    walker = init_commit_walker(latest_sha, nil)
    earliest = nil
    walker.each do |c|
      if c.parents.empty?
        earliest = c.oid
        break
      end
    end

    earliest
  end

  def get_latest_sha
    @repo.head.target.oid
  end

  #transforms commit tree into list of Version indexes
  def to_versions
    versions = []

    @tree.each_pair do |label, dt|
      label = label.to_s.gsub(/\A[r|v]/i, '')
      semver = SemVer.parse(label)
      if semver.nil?
        @logger.warn "to_versions: failed to parse label `#{label}` as semver"
        semver = label
      end

      dt[:commits].to_a.each do |c|
        is_version_commit = @sha_tag_idx.has_key?(  c[:sha] ) #if it's tagged commit, then it's stable release

        version = if semver
                    prefer = true
                    ( is_version_commit ? semver.to_s : "#{semver.to_s}+sha.#{c[:sha]}" )
                  else
                    prefer = false
                    "#{label}+sha.#{c[:sha]}"
                  end

        versions << Version.new({
          version: version,
          tag: ( is_version_commit ? label : nil ),
          status: ( is_version_commit ? "STABLE" : "PRERELEASE" ),
          released_at: c[:commited_at],
          sha1: c[:sha],
          md5: c[:short_sha],
          prefer_global: prefer
        })
      end
    end
    versions
  
  rescue Exception => e
    @logger.error e.backtrace.join('\n')
    return nil
  end
end

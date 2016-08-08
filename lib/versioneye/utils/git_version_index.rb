require 'csv'

#builds version index from git logs
class GitVersionIndex
  attr_reader :dir, :tree

  def initialize(repo_path, logger = nil)
    unless Dir.exist?(repo_path)
      raise "GitVersionIndex: Folder doesnt exist: `#{repo_path}`"
    end

    @logger = logger
    @logger ||= Versioneye::DynLog.new('log/godep.log', 10).log
    @dir = Dir.new repo_path

    @tree = {}
    @tag_sha_idx = {}
    @sha_tag_idx = {}
  end

  def build
    @logger.info "git_version_index: building index"

    first_sha = get_earliest_sha()
    latest_sha = get_latest_sha()

    tags = get_tags
    tag_idx = tags.to_a.reduce({}) do |acc, tag_row|
      acc[tag_row[0]] = tag_row[1]
      acc
    end

    @tag_sha_idx = {'0.0' => first_sha, 'head' => latest_sha}.merge tag_idx
    @sha_tag_idx = @tag_sha_idx.invert

    tag_shas = tags.map {|t| t[1]}
    start_shas = [first_sha] + tag_shas
    end_shas   = tag_shas + [latest_sha]
    commit_pairs = start_shas.zip end_shas


    start_commit = nil
    version_commits = {}
    commit_pairs.each do |start_sha, end_sha|
      version_label = @sha_tag_idx[start_sha]
      commits = get_commits_between_shas(start_sha, end_sha)

      #remove end_sha from the commits as it's belongs to the other version range and save it for next iteration
      next_start_commit = commits.pop

      version_commits[version_label] = {
        label: version_label,
        start_sha: start_sha,  #beginning of tagged commit
        end_sha: end_sha,      #beginning of next tag, not included in commits
        commits: ( start_commit.nil? ? commits : [start_commit] + commits ) #attach start commit only if it exists
      }

      start_commit = next_start_commit
    end

    @tree = version_commits
    @tree
  end

  def get_commits_between_shas(start_sha, end_sha)
    res = exec_in_dir do
      %x[git log --oneline --format="%h,%H,%ct,\u00bf%s\u00bf,%P" --ancestry-path --reverse #{start_sha}..#{end_sha}]
    end
    return if res.nil?

    process_logs res
  end

  def get_tags
    the_cmd = 'git log --date-order --reverse --tags --simplify-by-decoration --pretty=format:"%ct|%d|%H"'
    rows = exec_in_dir { %x[ #{the_cmd} ] }

    rows.to_s.split(/\n+/).to_a.reduce([]) do |acc, row|
      tag_info = process_tag_line(row)
      acc << tag_info unless tag_info.to_a.empty?
      acc
    end
  end

  def get_earliest_sha
    res = exec_in_dir { %x[git rev-list --max-parents=0 HEAD] }

    res.to_s.split(/\n/).first
  rescue
    return nil
  end

  def get_latest_sha
    res = exec_in_dir { %x[git rev-parse HEAD] }

    res.to_s.split(/\n/).first
  rescue
    return nil
  end

  def epoch_to_datetime(the_epoch)
    Time.at( the_epoch.to_i ).to_datetime
  rescue
    return nil
  end

  #transforms raw csv-lines to Commit document
  def process_logs(log_res)
    rows = CSV.parse(log_res, {force_quotes: true, skip_blanks: true, quote_char: "\u00bf" })
    rows.to_a.reduce([]) {|acc, r| acc << process_log_row(r); acc }
  rescue Exception => e 
    @logger.error "failed to parse: ", log_res
    @logger.error e.backtrace.join('\n')

    return nil
  end

  def process_log_row(csv_row)
    short_sha, full_sha, unix_dt, commit_msg, parent_shas = csv_row

    {
      sha: full_sha,
      short_sha: short_sha,
      commited_at: epoch_to_datetime(unix_dt),
      message: commit_msg,
      parents: parent_shas.to_s.split(/\s+/)
     }
  end

  #executes block in the repo dir and goes after that back to $PWD
  def exec_in_dir
    Dir.chdir(@dir) do
      yield if block_given?
    end
  end

  def process_tag_line(tag_line)
    epoch, tag_txt, tag_sha = tag_line.to_s.split(/\|/)
    return if tag_txt.to_s.empty? or tag_sha.to_s.empty?

    m = tag_txt.match(/tag: (?<label>\w+.+?)[\,|\)]/i)
    [m[:label], tag_sha.strip, epoch.to_i] if m and m[:label]
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

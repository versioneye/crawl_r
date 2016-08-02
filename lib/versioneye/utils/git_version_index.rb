require 'csv'

#builds version index from git logs
class GitVersionIndex
  attr_reader :dir, :tree

  def initialize(repo_path)
    unless Dir.exist?(repo_path)
      raise "GitVersionIndex: Folder doesnt exist: `#{repo_path}`"
    end

    @dir = Dir.new repo_path

    @tree = {}
    @tag_sha_idx = {}
    @sha_tag_idx = {}
  end

  def build
    first_sha = get_earliest_sha()
    latest_sha = get_latest_sha()

    @tag_sha_idx = {'0.0' => first_sha}.merge get_tag_shas
    @sha_tag_idx = @tag_sha_idx.invert

    start_shas = [first_sha] + @tag_sha_idx.values
    end_shas   = @tag_sha_idx.values + [latest_sha]
    commit_pairs = start_shas.zip end_shas


    version_commits = {}
    commit_pairs.each do |start_sha, end_sha|
      version_label = @sha_tag_idx[start_sha]
      commits = get_commits_between_shas(start_sha, end_sha)

      version_commits[version_label] = {
        label: version_label,
        start_sha: start_sha, #beginning of tagged commit
        end_sha: end_sha,      #beginning of next tag
        commits: commits
      }
    end

    @tree = version_commits
    @tree
  end

  def get_commits_between_shas(start_sha, end_sha)
    res = exec_in_dir do
      %x[git log --oneline --format="%h,%H,%ct,\u00bf%s\u00bf,%P" --ancestry-path #{start_sha}..#{end_sha}]
    end
    return if res.nil?

    process_logs res
  end

  def get_tag_shas
    tags = get_tags
    return if tags.nil?

    tags.reduce({}) do |acc, tag_lbl|
      acc[tag_lbl] = get_tag_sha tag_lbl
      acc
    end
  end

  def get_tags
    rows = exec_in_dir { %x[git tag --list] }

    rows.to_s.split(/\n+/)
  end

  def get_tag_sha(tag_label)
    res = exec_in_dir do
      %x[git rev-list -n 1 #{tag_label}]
    end

    res.to_s.gsub(/\n/, '')
  end

  def get_earliest_sha
    res = exec_in_dir { %x[git rev-list --max-parents=0 HEAD] }

    res.to_s.gsub(/\n/, '')
  rescue
    return nil
  end

  def get_latest_sha
    res = exec_in_dir { %x[git rev-parse HEAD] }

    res.to_s.gsub(/\n/, '')
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
    p "failed to parse: ", log_res
    p e.backtrace.inspect

    return nil
  end

  def process_log_row(csv_row)
    short_sha, full_sha, unix_dt, commit_msg, parent_shas = csv_row

    {
      sha: full_sha,
      short_sha: short_sha,
      epoch: epoch_to_datetime(unix_dt),
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
end

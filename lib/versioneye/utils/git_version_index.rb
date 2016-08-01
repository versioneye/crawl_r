require 'csv'

#builds version index from git logs
class GitVersionIndex
  attr_reader :index, :path
  
  def initialize(repo_path)
    unless Dir.exist?(repo_path)
      raise "GitVersionIndex: Folder doesnt exist: `#{repo_path}`"
    end
    
    @dir = Dir.new repo_path

    @index = {}
  end

  def get_logs(page, n = 50)
    res = exec_in_dir do
      %x[git log --oneline --format="%h,%H,%ct,%s,%P" --skip=#{n * page} --max-count=#{n}]
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

  def epoch_to_datetime(the_epoch)
    Time.at( the_epoch.to_i ).to_datetime
  rescue
    return nil
  end

  #transforms raw csv-lines to Commit document
  def process_logs(log_res)
    rows = CSV.parse log_res
    rows.to_a.reduce([]) {|acc, r| acc << process_log_row(r); acc }
  end

  def process_log_row(csv_row)
    short_sha, full_sha, unix_dt, commit_msg, parent_shas = csv_row

    {
      sha: full_sha,
      short_sha: short_sha,
      epoch: epoch_to_datetime(unix_dt),
      message: commit_msg,
      parents: parent_shas.to_s.split(/\s+/), 
     }
  end

  #executes block in the repo dir and goes after that back to $PWD
  def exec_in_dir
    Dir.chdir(@dir) do
      yield if block_given?
    end
  end
end

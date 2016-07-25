require 'narray'
require 'tf-idf-similarity'

class LicenseMatcher
  attr_reader :corpus, :licenses
  
  def initialize(files_path)
    @licenses = get_license_names(files_path)
    @corpus = read_corpus(files_path)
  end

  #reads licenses content from the files_path and returns list of texts
  def read_corpus(files_path)
    file_names = get_license_names(files_path)
    
    file_names.reduce([]) do |acc, file_name|
      txt = File.read("#{files_path}/#{file_name}")

      if txt
        acc << TfIdfSimilarity::Document.new(txt)
      end
      acc
    end
  end

  def get_license_names(files_path)
    Dir.entries(files_path).to_a.delete_if {|name| ( name == '.' or name == '..' or name =~ /\w+\.py/i )}
  end

  def match_by_text(text, n = 3)
    clean_text = text.to_s.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    text_doc = TfIdfSimilarity::Document.new(clean_text)
    match_corpus = @corpus.push text_doc

    model = TfIdfSimilarity::BM25Model.new(match_corpus, :library => :narray)
    text_doc_id = model.document_index(text_doc)
    results = get_row(model.similarity_matrix, text_doc_id)

    score_map = {}
    results.each_with_index do |score, i|
      license_id = @licenses.fetch(i, 'doc')
      score_map[license_id] = score.first
    end

    top_matches(score_map, n)
  end

  #returns top-N matching licenses with matching score 
  def top_matches(score_map, n = 3)
    score_map.sort_by {|lic, score| -score}.delete_if {|lic, score| lic == 'doc'}.take(n)
  end

  def get_row(sim_matrix, row_id)
    last_col = sim_matrix.shape.last - 1
    sim_matrix.slice(row_id, 0..last_col).to_a
  end
end

require 'nokogiri'
require 'narray'
require 'tf-idf-similarity'

class LicenseMatcher
  attr_reader :corpus, :licenses
  
  CUSTOM_CORPUS_FILES_PATH = 'data/custom_licenses' #where to look up non SPDX licenses

  def initialize(files_path)
    spdx_ids, spdx_docs = read_corpus(files_path)
    custom_ids, custom_docs = read_corpus(CUSTOM_CORPUS_FILES_PATH)
    @licenses = spdx_ids + custom_ids
    @corpus = spdx_docs + custom_docs
  end

  #reads licenses content from the files_path and returns list of texts
  def read_corpus(files_path)
    file_names = get_license_names(files_path)
    
    docs = file_names.reduce([]) do |acc, file_name|
      content = File.read("#{files_path}/#{file_name}")
      txt = safe_encode(content)
      if txt
        acc << TfIdfSimilarity::Document.new(txt)
      else
        p "read_corpus: failed to encode content of corpus #{files_path}/#{file_name}"
      end

      acc
    end

    [file_names, docs]
  end

  def get_license_names(files_path)
    Dir.entries(files_path).to_a.delete_if {|name| ( name == '.' or name == '..' or name =~ /\w+\.py/i or name =~ /.DS_Store/i )}
  end

  def match_text(text, n = 3)
    clean_text = safe_encode(text) 
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

  def match_html(html_doc, n = 3)
    doc = Nokogiri.HTML(html_doc)
    return [] if doc.nil?

    body_txt = doc.xpath(
      '//p | //h1 | //h2 | //h3 | //h4 | //h5 | //h6 | //em | // strong |//td |//pre |//li[not(@class)]'
    ).text.to_s.strip
   
    if body_txt.empty?
      p "match_html: document didnt pass noise filter, will use whole body content"
      body_txt = doc.xpath('//body').text.to_s.strip
    end

    if body_txt.empty?
      p "match_html: didnt find enough text from html_doc: #{html_doc}"
      return [] 
    end

    match_text(body_txt, n)
  end

  #returns top-N matching licenses with matching score 
  def top_matches(score_map, n = 3)
    score_map.sort_by {|lic, score| -score}.delete_if {|lic, score| lic == 'doc'}.take(n)
  end

  def get_row(sim_matrix, row_id)
    last_col = sim_matrix.shape.last - 1
    sim_matrix.slice(row_id, 0..last_col).to_a
  end

  def safe_encode(txt)
    txt.to_s.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  rescue
    p "Failed to encode text:\n #{txt}"
    return nil
  end
end

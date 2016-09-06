require 'nokogiri'
require 'narray'
require 'tf-idf-similarity'
require 'json'

class LicenseMatcher
  attr_reader :corpus, :licenses, :model, :url_index
  
  DEFAULT_CORPUS_FILES_PATH = 'data/licenses/texts/plain'
  CUSTOM_CORPUS_FILES_PATH  = 'data/custom_licenses' #where to look up non SPDX licenses
  LICENSE_JSON_FILE         = 'data/licenses.json'

  def initialize(files_path = DEFAULT_CORPUS_FILES_PATH, license_json_file = LICENSE_JSON_FILE)
    spdx_ids, spdx_docs = read_corpus(files_path)
    custom_ids, custom_docs = read_corpus(CUSTOM_CORPUS_FILES_PATH)
    @licenses = spdx_ids + custom_ids
    @corpus = spdx_docs + custom_docs
    
    licenses_json_doc = read_json_file license_json_file
    @url_index = read_license_url_index(licenses_json_doc)
    @model = TfIdfSimilarity::BM25Model.new(@corpus, :library => :narray)
  end

  def match_text(text, n = 3)
    clean_text = safe_encode(text)
    test_doc   = TfIdfSimilarity::Document.new(clean_text, {:id => "test"})

    mat1 = @model.instance_variable_get(:@matrix)
    mat2 = doc_tfidf_matrix(test_doc)

    n_docs = @model.documents.size
    dists = []
    n_docs.times do |i|
      dists << [i, cos_sim(mat1[i, true], mat2)]
    end

    top_matches = dists.sort {|a,b| b[1] <=> a[1]}.take(n)
    
    #translate doc numbers to id
    top_matches.reduce([]) do |acc, doc_id_and_score|
      doc_id, score = doc_id_and_score
      acc << [ @model.documents[doc_id].id, score ] 
      acc
    end
  end

  def match_html(html_doc, n = 3)
    doc = Nokogiri.HTML(html_doc)
    return [] if doc.nil?

    body_txt = doc.xpath(
      '//p | //h1 | //h2 | //h3 | //h4 | //h5 | //h6 | //em | // strong |//td |//pre 
			|//li[not(@id) and not(@class) and not(a)]'
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

  #matches License.url with urls in Licenses.json and returns tuple [spdx_id, score]
  def match_url(the_url)
		the_url = the_url.to_s.strip
		spdx_id = nil
    @url_index.each do |lic_url, lic_id|
 			lic_url = lic_url.to_s.strip.gsub(/https?:\/\//i, '').gsub(/www\./, '') #normalizes urls in the file
   		matcher = Regexp.new("^https?:\/\/(www\.)?#{lic_url}.*$", Regexp::IGNORECASE)

			if matcher.match(the_url)
				spdx_id = lic_id
				break
			end
		end
		
		return [] if spdx_id.nil?

    [spdx_id, 1.0] 
  end

#-- helpers
  
  # transforms document into TF-IDF matrix used for comparition
  def doc_tfidf_matrix(doc)
    arr = Array.new(@model.terms.size) do |i|
      the_term = @model.terms[i]
      if doc.term_count(the_term) > 0
        #calc score only for words that exists in the test doc and the corpus of licenses
        model.idf(the_term) * model.tf(doc, the_term)
      else
        0.0
      end
    end

    NArray[*arr]
  end

  # calculates cosine similarity between 2 TF-IDF vector
  def cos_sim(mat1, mat2)
    length = (mat1 * mat2).sum
    norm   = Math::sqrt((mat1 ** 2).sum) * Math::sqrt((mat2 ** 2).sum)

    ( norm > 0 ? length / norm : 0.0)
  end


  def read_json_file(file_path)
    JSON.parse(File.read(file_path), {symbolize_names: true})
  rescue
    p "Failed to read json file `#{file_path}`"
    nil
  end

  #reads license urls from the license.json and builds a map {url : spdx_id}
  def read_license_url_index(spdx_licenses)
    url_index = {}
    spdx_licenses.each {|lic| url_index.merge! process_spdx_item(lic) }
    url_index
  end

  def process_spdx_item(lic)
    url_index = {}
    lic_id = lic[:id]
    return url_index if lic_id.nil?

    lic[:links].to_a.each {|x| url_index[x[:url]] = lic_id }
    lic[:text].to_a.each {|x| url_index[x[:url]] = lic_id } 

    url_index
  end

  #reads licenses content from the files_path and returns list of texts
  def read_corpus(files_path)
    file_names = get_license_names(files_path)
    
    docs = file_names.reduce([]) do |acc, file_name|
      content = File.read("#{files_path}/#{file_name}")
      txt = safe_encode(content)
      if txt
        acc << TfIdfSimilarity::Document.new(txt, :id => file_name)
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

  #returns top-N matching licenses with matching score 
  def safe_encode(txt)
    txt.to_s.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  rescue
    p "Failed to encode text:\n #{txt}"
    return nil
  end
end

require 'nokogiri'
require 'narray'
require 'tf-idf-similarity'
require 'json'

class LicenseMatcher
  attr_reader :corpus, :licenses, :model, :url_index, :rules, :spdx_ids, :custom_ids

  DEFAULT_CORPUS_FILES_PATH = 'data/licenses/texts/plain'
  CUSTOM_CORPUS_FILES_PATH  = 'data/custom_licenses' #where to look up non SPDX licenses
  LICENSE_JSON_FILE         = 'data/licenses.json'

  def get_rules
    #NB: order matters for AGPL and GPL
    {
      "AGPL-1.0"      => [
                          /\bAGPL\b/i,
                          /\bAffero\s+General\s+Public\s+License\s+[v]?1\b/i,
                          /\bAFFERO\s+GENERAL\s+PUBLIC\b/i
                         ],
      "AGPL-3.0"      => [
                          /\bAGPL[-|v]?3/i,
                          /\bGNU\s+Affero\s+General\s+Public\s+License\s+[v]?3/i
                         ],
      "GPL-1.0"       => [/\bGPL[-|v]?1\b/i, /\bGPL[-|v]?1\.0\b/i],
      "GPL-2.0"       => [/\bGNU\s+GPL\sv2/i, /\bGPL[v|-]?2\b/i, /\bGPL\s+[v]?2\b/i ],
      "GPL-3.0"       => [
                          /\bGPL[-|v]?3\b/i, /\bGPL\s+3/i, /\bGNU\s+GPL\b/i,
                          /\b[\(]?GPL[\)]?\b/i
                         ],
      "MIT"           => [/\bMIT\b/i],
      "AAL"           => [/\bAAL\b/i],
      "AFL-1.1"       => [/\bAFL[-|v]?1\b/i, /\bafl[-|v]?1\.1\b/i],
      "AFL-1.2"       => [/\bAFL[-|v]?1\.2\b/i],
      "AFL-2.0"       => [/\bAFL[-|v]?2\b/i, /\bafl[-|v]?2\.1\b/i],
      "AFL-2.1"       => [/\bAFL[-|v]?2\.1\b/i],
      "AFL-3.0"       => [/\bAFL[-|v]?3/i],
      "Apache-1.0"    => [/\bAPACHE[-|v]?1\b/, /\bAPACHE[-|v]?1.0\b/],
      "Apache-1.1"    => [/\bAPACHE[-|v]?1\.1\b/i],
      "Apache-2.0"    => [
                          /\bAPACHE[-|v]?2/i, /\bAPACHE\b/i, /\bAPACHE\s+2\.0\b/i,
                          /\bAPL\s+2\.0\b/i, /\bAPL[\.|-|v]?2\b/i
                         ],
      "APL-1.0"       => [/\bapl[-|v]?1\b/i, /\bapl[-|v]?1\.0\b/i],
      "APSL-1.0"      => [/\bapsl[-|v]?1\b/i, /\bapsl[-|v]?1\.0\b/i],
      "APSL-1.1"      => [/\bapsl[-|v]?1\.1\b/i],
      "APSL-1.2"      => [/\bapsl[-|v]?1\.1\b/i],
      "APSL-2.0"      => [/\bapsl[-|v]?1\.1\b/i],
      "Artistic-1.0"  => [/\bartistic[-|v]?1\b/i, /\bartistic[-|v]?1\.0/i],
      "Artistic-2.0"  => [/\bartistic[-|v]?2\b/i, /\bartistic[-|v]?2\.0\b/i],
      "BSD-2-Clause"  => [/\bBSD[-|v]?2/i],
      "BSD-3-Clause"  => [/\bBSD[-|v]?3/i],
      "BSD-4-Clause"  => [/\bBSD[-|v]?4/i, /\bBSD\b/i, /\bBSD\s+LICENSE\b/i],
      "BSL-1.0"       => [/\bbsl[-|v]?1\b/i, /\bBSL[-|v]?1\.0\b/i],
      "CDDL-1.0"      => [/\bCDDL[-|v]?1\b/i, /\bCDDL[-|v]?1\.0\b/i],
      "CPL-1.0"       => [/\bCPL[-|v]?1\b/i, /\bCPL[-|v]?1\.0\b/i],
      "ECL-1.0"       => [/\bECL[-|v]?1\b/i, /\bECL[-|v]?1\.0\b/i],
      "ECL-2.0"       => [/\bECL[-|v]?2\b/i, /\bECL[-|v]?2\.0\b/i],
      "EFL-1.0"       => [/\bEFL[-|v]?1\b/i, /\bEFL[-|v]?1\.0\b/i],
      "EFL-2.0"       => [/\bEFL[-|v]?2\b/i, /\bEFL[-|v]?2\.0\b/i],
      "ISC"           => [/\bISC\s+LICENSE\b/i, /\b[\(]ISCL[\)]\b/i, /\bISC\b/i],
      "LGPL-2.0"      => [/\bLGPL[-|v]?2\b/i, /\bLGPL[-|v]?2\.0\b/i],
      "LGPL-2.1"      => [/\bLGPL[-|v]?2\.1\b/i],
      "LGPL-3.0"      => [/\bLGPL[-|v]?3\b/i, /\bLGPL[-|v]?3\.0\b/i,
                          /\b[\(]?LGPL[\)]?/i,
                          /\bLESSER\s+GENERAL\s+PUBLIC\s+License\s+[v]?3\b/i
                         ],
      "MPL-1.0"       => [/\bMPL[-|v]?1\b/i, /\bMPL[-|v]?1\.0\b/i],
      "MPL-1.1"       => [/\bMPL[-|v]?1\.1\b/i],
      "MPL-2.0"       => [
                          /\bMPL[-|v]?2\b/i, /\bMPL[-|v]?2\.0\b/i,
                          /\bMOZILLA\s+PUBLIC\s+LICENSE\s+2\.0\b/i,
                          /\b[\(]?MPL\s+2\.0[\)]?\b/i, /\b[\(]?MPL[\)]?\b/i
                         ],
      "MS-PL"         => [/\bMS-PL\b/i],
      "MS-RL"         => [/\bMS-RL\b/i],
      "NGPL"          => [/\bNGPL\b/i],
      "OSL-1.0"       => [/\bOSL[-|v]?1\b/i, /\b\OSL[-|v]?1\.0\b/i],
      "OSL-2.0"       => [/\bOSL[-|v]?2\b/i, /\bOSL[-|v]2\.0?\b/i],
      "OSL-2.1"       => [/\bOSL[-|v]?2\.1\b/i],
      "OSL-3.0"       => [/\bOSL[-|v]?3/i, /\bOSL[-|v]?3\.0\b/i],
      "Python-2.0"    => [/\bPython[-|v]?2\b/i, /\bPython[-|v]?2\.0\b/i],
      "RPL-1.1"       => [/\bRPL[-|v]?1\b/i, /\bRPL[-|v]?1\.1\b/i],
      "RPL-1.5"       => [/\bRPL[-|v]?1\.5\b/i],
      "Sleepycat"     => [/\bSleepyCat\b/i],
      "W3C"           => [/\bW3C\b/i],
      "Beerware"      => [/\bBEERWARE\b/i],
      "CC-BY-1.0"     => [/\bCC?BY?1\b/i, /\bCC?BY?1\.0\b/i],
      "CC-BY-2.0"     => [/\bCC?BY?2\b/i, /\bCC?BY?2\.0\b/i],
      "CC-BY-2.5"     => [/\bCC?BY?2\.5\b/i],
      "CC-BY-3.0"     => [/\bCC?BY?3\b/i, /\bCC?BY?3\.0\b/i, /\bCC\s+BY\s+3\.0\b/],
      "CC-BY-4.0"     => [/\bCC?BY?4\b/i, /\bCC?BY?4\.0\b/i],
      "OpenSSL"       => [/\bOPENSSL\b/i],
      "Unlicense"     => [/\bUNLICENSE\b/i],
      "WTFPL"         => [/\bWTFPL\b/i],
      "X11"           => [/\bX11\b/i],
      "ZPL-1.1"       => [/\bZPL[-|v]?1\b/i, /\bZPL[-|v]?1\.1\b/i],
      "ZPL-2.1"       => [
                          /\bZPL[-|v]?2\b/i, /\bZPL[-|v]?2\.1\b/i,
                          /\bZPL\s+2\.1\b/i, /\bZOPE\s+PUBLIC\s+LICENSE\b/i
                         ]
    }
  end

  def get_rule_ids
    ids = {}
    @rules.keys.each do |the_key|
      the_id = the_key.to_s.downcase.strip
      ids[the_id] = the_key
    end

    ids
  end

  def log
    Versioneye::Log.instance.log
  end

  def initialize(files_path = DEFAULT_CORPUS_FILES_PATH, license_json_file = LICENSE_JSON_FILE)
    spdx_ids, spdx_docs = read_corpus(files_path)
    custom_ids, custom_docs = read_corpus(CUSTOM_CORPUS_FILES_PATH)

    @licenses = spdx_ids + custom_ids
    @spdx_ids = spdx_ids
    @custom_ids = custom_ids
    @corpus = spdx_docs + custom_docs

    licenses_json_doc = read_json_file license_json_file
    @url_index = read_license_url_index(licenses_json_doc)
    @model = TfIdfSimilarity::BM25Model.new(@corpus, :library => :narray)
    @rules = get_rules
    true
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
      log.error "match_html: document didnt pass noise filter, will use whole body content"
      body_txt = doc.xpath('//body').text.to_s.strip
    end

    if body_txt.empty?
      log.info "match_html: didnt find enough text from html_doc: #{html_doc}"
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

  # finds matching regex rules in the license name
  # ps: not very efficient, but good enough to handle special cases;
  # @args:
  #   text - string, a name of license,
  #   early_exit  - boolean, default: true, will only return first match
  # @returns:
  #   [[spdx_id, confidence]]
  def match_rules(text, early_exit = true)
    matches = []
    text_ = text.to_s.strip

    @rules.each do |spdx_id, rules|
      if matches_any_rule?(rules, text_)
        matches << [spdx_id, 1.0]
        break if early_exit
      end
    end

    matches
  end

  def matches_any_rule?(rules, license_name)
    rules.any? {|rule| rule.match(license_name.to_s) }
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
    log.info "Failed to read json file `#{file_path}`"
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
        log.error "read_corpus: failed to encode content of corpus #{files_path}/#{file_name}"
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
     "Failed to encode text:\n #{txt}"
    return nil
  end
end

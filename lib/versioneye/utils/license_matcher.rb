require 'nokogiri'
require 'narray'
require 'tf-idf-similarity'
require 'json'

class LicenseMatcher

  attr_reader :corpus, :licenses, :model, :url_index, :rules, :spdx_ids, :custom_ids

  DEFAULT_CORPUS_FILES_PATH = 'data/spdx_licenses/plain'
  CUSTOM_CORPUS_FILES_PATH  = 'data/custom_licenses' # Where to look up non SPDX licenses
  LICENSE_JSON_FILE         = 'data/spdx_licenses/licenses.json'

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

    # Translate doc numbers to id
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


  # Matches License.url with urls in Licenses.json and returns tuple [spdx_id, score]
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
    ignore_rules = get_ignore_rules()

    #if text is in ignore list, then return same text, but negative score as it's spam
    return [text_, -1] if matches_any_rule?(ignore_rules, text_)

    @rules.each do |spdx_id, rules|
      if matches_any_rule?(rules, text_)
        matches << [spdx_id, 1.0]
        break if early_exit
      end
    end

    matches
  end

  def matches_any_rule?(rules, license_name)
    rules.any? {|rule| rule.match(license_name.to_s) != nil }
  end


#-- helpers

  # Transforms document into TF-IDF matrix used for comparition
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


  # Calculates cosine similarity between 2 TF-IDF vector
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


  # Reads license urls from the license.json and builds a map {url : spdx_id}
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


  # Reads licenses content from the files_path and returns list of texts
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


  # Returns top-N matching licenses with matching score
  def safe_encode(txt)
    txt.to_s.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
  rescue
     "Failed to encode text:\n #{txt}"
    return nil
  end


  def get_ignore_rules
    [
      /\bProprietary\b/i, /\bOther\/Proprietary\b/i, /\bLICEN[C|S]E\.\w{2,8}\b/i,
      /^LICEN[C|S]ING\.\w{2,8}\b/i, /^COPYING\.\w{2,8}/i,
      /\bDFSG\s+APPROVED\b/i, /\bSee\slicense\sin\spackage\b/i,
      /\bFree\s+for\s+non[-]?commercial\b/i, /\bFree\s+To\s+Use\b/i,
      /\bFree\sFor\sHome\sUse\b/i, /\bFree\s+For\s+Educational\b/i,
      /^Freely\s+Distributable$/i, /^COPYRIGHT\s+\d{2,4}/i,
      /^Copyright\s+\(c\)\s+\d{2,4}\b/i, /^COPYRIGHT$/i, /^COPYRIGHT\.\w{2,8}\b/i,
      /^\(c\)\s+\d{2,4}\d/,
      /^LICENSE$/i, /^FREE$/i, /^See\sLicense$/i, /^TODO$/i, /^FREEWARE$/i,
      /^All\srights\sreserved$/i, /^COPYING$/i, /^OTHER$/i, /^NONE$/i, /^DUAL$/i,
      /^KEEP\s+IT\s+REAL$/i, /\bSee\s+LICENSE\s+file\b/i, /^LICEN[C|S]E$/i,
      /^PUBLIC$/i, /^see file LICENSE$/i, /^__license__$/i,
      /^GNU$/i, /^GNU[-|\s]?v3$/i, /^OSI\s+Approved$/i, /^OSI$/i,
      /^https?:\/\/github.com/i
    ]
  end

  def get_rules
    {
      "AAL"           => [/\bAAL\b/i, /\bAttribution\s+Assurance\s+License\b/i],
      "AFL-1.1"       => [/\bAFL[-|v]?1\b/i, /\bafl[-|v]?1\.1\b/i],
      "AFL-1.2"       => [/\bAFL[-|v]?1\.2\b/i],
      "AFL-2.0"       => [/\bAFL[-|v]?2\b/i, /\bafl[-|v]?2\.1\b/i],
      "AFL-2.1"       => [/\bAFL[-|v]?2\.1\b/i],
      "AFL-3.0"       => [
                          /\bAFL[-|v]?3/i, /\bAcademic\s+Free\s+License\b/i, /^AFL$/i,
                          /\bhttps?:\/\/opensource\.org\/licenses\/academic\.php\b/i
                          ],
      "AGPL-1.0"      => [
                          /\bAGPL\b/i, /\bAGPL[_|-|v]?2\b/i,
                          /\bAffero\s+General\s+Public\s+License\s+[v]?1\b/i,
                          ],
      "AGPL-3.0"      => [
                          /\bAGPL[-|v]?3/i, /\bAPGLv?3\b/i,
                          /\bGNU\s+Affero\s+General\s+Public\s+License\s+[v]?3/i,
                          /\bAFFERO\sGNU\sPUBLIC\sLICENSE\sv3\b/i,
                          /\bGnu\sAffero\sPublic\sLicense\sv3+?\b/i,
                          /\bAFFERO GENERAL PUBLIC\b/,
                          /^AFFERO$/i
                         ],
      "Apache-1.0"    => [/\bAPACHE[-|v]?1\b/, /\bAPACHE[-|v]?1.0\b/],
      "Apache-1.1"    => [/\bAPACHE[-|v]?1\.1\b/i],
      "Apache-2.0"    => [
                          /\bAPACHE[-|v]?2/i, /\bAPACHE\s+2\.0\b/i,
                          /\bAPL\s+2\.0\b/i, /\bAPL[\.|-|v]?2\b/i, /\bASL\s+2\.0\b/i,
                          /\bASL[-|v|\s]?2\b/i, /\bAPACHE\s+LICENSE\s+VERSION\s+2\.0\b/i,
                          /\bALv2\b/i, /\bASF[-|\s]?2\.0\b/i, /\bAPACHE\b/i, /^ASL$/i,
                          /\bASL\s+v?\.2\.0\b/i
                         ],
      "APL-1.0"       => [/\bapl[-|v]?1\b/i, /\bapl[-|v]?1\.0\b/i, /^APL$/i],
      "APSL-1.0"      => [/APSL[-|v]1\.0/i, /APSL[-|v]1/i, /APPLE\s+PUBLIC\s+SOURCE/i],
      "APSL-1.1"      => [/APSL[-|v]1\.1/i],
      "APSL-1.2"      => [/APSL[-|v]1\.2/i],
      "APSL-2.0"      => [/APSL[-|v]2\.0/i],
      "Artistic-1.0"  => [/\bartistic[-|v]?1\b/i, /\bartistic[-|v]?1\.0/i],
      "Artistic-2.0"  => [/\bartistic[-|v]?2\b/i, /\bartistic[-|v]?2\.0\b/i,
                          /\bARTISTIC\s+LICENSE\b/i, /\bARTISTIC\b/i],
      "Artistic-1.0-Perl" => [/\bArtistic[-|\s]?1\.0\-Perl\b/i, /^$PerlArtistic/i],
      "Beerware"      => [
                          /\bBEERWARE\b/i, /\bBEER\s+LICEN[c|s]E\b/i,
                          /\bBEER[-|\s]WARE\b/i, /^BEER$/i,
                          /\bBuy\ssnare\sa\sbeer\b/i,
                          /\bWISKY[-|_|\s]?WARE\b/i
                         ],
      "BSD-2-Clause"  => [/\bBSD[-|v]?2/i, /^FREEBSD$/i, /^OPENBSD$/i],
      "BSD-3-Clause"  => [/\bBSD[-|v]?3/i, /\bBSD[-|\s]3[-\s]CLAUSE\b/i,
                          /\bBDS[-|\s]3[-|\s]CLAUSE\b/i, /^BDS$/i, /^various\/BSDish$/],
      "BSD-4-Clause"  => [
                          /\bBSD[-|v]?4/i, /\bBSD\b/i, /\bBSD\s+LICENSE\b/i,
                          /\bBSD-4-CLAUSE\b/i,
                          /^http:\/\/en\.wikipedia\.org\/wiki\/BSD_licenses$/i
                         ],
      "BSL-1.0"       => [
                          /\bbsl[-|v]?1\b/i, /\bBSL[-|v]?1\.0\b/i, /^BOOST$/i,
                          /\bBOOST\s+SOFTWARE\s+LICENSE\b/i,
                          /\bBoost\sLicense\s1\.0\b/i
                         ],
      "CC0-1.0"       => [
                          /\bCC0[-|v|\s]?1\.0\b/i, /\bCC0[-|v]?1\b/i,
                          /\bCC[-|\s]?[0|o]\b/i, /\bCreative\s+Commons\s+0\b/i
                         ],
      "CC-BY-1.0"     => [/\bCC.BY.1\b/i, /\bCC.BY.1\.0\b/i, /^CC[-|_|\s]?BY$/i],
      "CC-BY-2.0"     => [/\bCC.BY.2\b/i, /\bCC.BY.2\.0\b/i],
      "CC-BY-2.5"     => [/\bCC.BY.2\.5\b/i],
      "CC-BY-3.0"     => [/\bCC.BY.3\b/i, /\bCC.BY.3\.0\b/i, /\bCC\s+BY\s+3\.0\b/],
      "CC-BY-4.0"     => [
                          /^CC[-|\s]?BY[-|\s]?4\.0$/i, /\bCC.BY.4\b/i, /\bCC.BY.4\.0\b/i,
                          /\bCREATIVE\s+COMMONS\s+ATTRIBUTION\s+[v]?4\.0\b/i,
                          /\bCREATIVE\s+COMMONS\s+ATTRIBUTION\b/i
                         ],
      "CC-BY-SA-1.0"  => [/^CC[-|\s]BY.SA.1\.0$/i, /\bCC[-|\s]BY.SA[-|\s]1\.0\b/i],
      "CC-BY-SA-2.0"  => [/^CC[-|\s]BY.SA.2\.0$/i, /\bCC[-|\s]BY.SA[-|\s]2\.0\b/i],
      "CC-BY-SA-2.5"  => [/^CC[-|\s]BY.SA.2\.5$/i, /\bCC[-|\s]BY.SA[-|\s]2\.5\b/i],
      "CC-BY-SA-3.0"  => [/^CC[-|\s]BY.SA.3\.0$/i, /\bCC[-|\s]BY.SA[-|\s]3\.0\b/i,
                          /\bCC3\.0[-|_|\s]BY.SA\b/i,
                          /\bhttp:\/\/creativecommons\.org\/licenses\/by-sa\/3\.0\/\b/i],
      "CC-BY-SA-4.0"  => [
                          /^CC[-|\s]BY.SA.4\.0$/i, /\bCC[-|\s]BY.SA[-|\s]4\.0\b/i,
                          /CCSA-4\.0/i
                         ],
      "CC-BY-NC-1.0"  => [/\bCC[-|\s]BY.NC[-|\s]1\.0\b/i, /\bCC[-|\s]BY.NC\b/i],
      "CC-BY-NC-2.0"  => [/\bCC[-|\s]BY.NC[-|\s]2\.0\b/i],
      "CC-BY-NC-2.5"  => [/\bCC[-|\s]BY.NC[-|\s]2\.5\b/i],
      "CC-BY-NC-3.0"  => [/\bCC[-|\s]BY.NC[-|\s]3\.0\b/i,
                          /\bCreative\s+Commons\s+Non[-]?Commercial[,]?\s+3\.0\b/i],
      "CC-BY-NC-4.0"  => [/\bCC[-|\s]BY.NC[-|\s]4\.0\b/i],
      "CC-BY-NC-SA-1.0" => [ /\bCC[-|\s+]BY.NC.SA[-|\s+]1\.0\b/i,
                             /\bCC[-|\s+]BY.NC.SA[-|\s+]1\b/i,
                             /\bCC[-|\s+]BY.NC.SA[-|\s+]\b/i,
                        ],
      "CC-BY-NC-SA-2.0" =>  [/\bCC[-|\s]?BY.NC.SA[-|\s]?2\.0\b/i],
      "CC-BY-NC-SA-2.5" =>  [/\bCC[-|\s]?BY.NC.SA[-|\s]?2\.5\b/i],
      "CC-BY-NC-SA-3.0" =>  [
                              /\bCC[-|\s]?BY.NC.SA[-|\s]?3\.0\b/i,
                              /\bBY[-|\s]NC[-|\s]SA\s3\.0\b/i,
                              /^http:\/\/creativecommons.org\/licenses\/by-nc-sa\/3.0\/us\/$/i
                            ],
      "CC-BY-NC-SA-4.0" => [/\bCC[-|\s]?BY.NC.SA[-|\s]?4\.0\b/i],
      "CC-BY-ND-1.0"  => [/\bCC[-|\s]BY.ND[-|\s]?1\.0\b/i],
      "CC-BY-ND-2.0"  => [/\bCC[-|\s]BY.ND[-|\s]?2\.0\b/i],
      "CC-BY-ND-2.5"  => [/\bCC[-|\s]BY.ND[-|\s]?2\.5\b/i],
      "CC-BY-ND-3.0"  => [/\bCC[-|\s]BY.ND[-|\s]?3\.0\b/i],
      "CC-BY-ND-4.0"  => [/\bCC[-|\s]BY.ND[-|\s]?4\.0\b/i],

      "CDDL-1.0"      => [
                          /\bCDDL[-|v]?1\b/i, /\bCDDL[-|v]?1\.0\b/i, /^CDDL$/i,
                          /\bCDDL\s+LICEN[C|S]E\b/i,
                          /\bCOMMON\sDEVELOPMENT\sAND\sDISTRIBUTION\sLICENSE\b/i
                         ],
      "CECILL-B"      => [/\bCECILL[_|-|\s+]B\b/, /\bCECILLB\b/i],
      "CECILL-C"      => [/\bCECILL[_|-|\s+]C\b/, /\bCECILLC\b/i],
      "CECILL-1.0"    => [
                          /\bCECILL[_|-|\s]?1\.0\b/i, /^CECILL$/i,
                          /\bCECILL\s+v?1\.2\b/i,
                          /^http:\/\/www\.cecill\.info\/licences\/Licence_CeCILL-C_V1-en.html$/i,
                          /\bhttp:\/\/www\.cecill\.info\b/i
                         ],
      "CECILL-2.1"    => [
                          /\bCECILL[-|_|\s]?2\.1\b/i, /\bCECILL[\s|_|-]?v?2\b/i,
                          /\bCECILL\sVERSION\s2\.1\b/i
                         ],
      "CPL-1.0"       => [
                            /\bCPL[-|v]?1\b/i, /\bCPL[-|v]?1\.0\b/i,
                            /\bCommon\s+Public\s+License\b/i, /^CPL$/i
                          ],
      "D-FSL-1.0"     => [
                            /\bD-?FSL-?1\.0\b/i, /\bD-?FSL[-|v]?1\b/,
                            /\bGerman\sFREE\sSOFTWARE\b/i,
                            /\bDeutsche Freie Software Lizenz\b/i
                          ],
      "ECL-1.0"       => [/\bECL[-|v]?1\b/i, /\bECL[-|v]?1\.0\b/i],
      "ECL-2.0"       => [
                          /\bECL[-|v]?2\b/i, /\bECL[-|v|\s]?2\.0\b/i,
                          /\bEDUCATIONAL\s+COMMUNITY\s+LICENSE[,]?\sVERSION\s2\.0\b/i
                         ],
      "EFL-1.0"       => [/\bEFL[-|v]?1\b/i, /\bEFL[-|v]?1\.0\b/i],
      "EFL-2.0"       => [
                          /\bEFL[-|v]?2\b/i, /\bEFL[-|v]?2\.0\b/i,
                          /\bEiffel\sForum\sLicense,?\sversion\s2/i
                         ],
      "EPL-1.0"       => [
                          /\bEPL[-|v]?1\.0\b/i, /\bEPL[-|v]?1\b/i, /\bEPL\b/,
                          /\bECLIPSE\s+PUBLIC\s+LICENSE\s+[v]?1\.0\b/i,
                          /\bECLIPSE\s+PUBLIC\s+LICENSE\b/i,
                          /^ECLIPSE$/i
                         ],
      "EUPL-1.0"      => [/\b[\(]?EUPL[-|\s]?1\.0[\)]?\b/i],
      "EUPL-1.1"      => [
                          /\b[\(]?EUPL[-|\s]?v?1\.1[\)]?\b/i,
                          /\bEUROPEAN\s+UNION\s+PUBLIC\s+LICENSE\s+1\.1\b/i,
                          /^EUPL$/i
                         ],
      "GPL-1.0"       => [
                          /\bGPL[-|v]?1\b/i, /\bGPL[-|v]?1\.0\b/i,
                          /\bGeneral\s+Public\s+Licen[c|s]e\b/i,
                          /^GNU\s+PUBLIC$/i, /^GNU\sPUBLIC\sLICEN[S|C]E$/i
                         ],
      "GPL-2.0"       => [
                          /\bGNU\s+GPL\sv2/i, /\bGPL[v|-]?2\b/i, /\bGPL\s+[v]?2\b/i,
                          /\bGNU\s+PUBLIC\s+LICENSE\s+2\.0\b/i,
                          /\bGNU\s+PUBLIC\s+License\sV?2\b/i,
                          /\bGNU\s+GPL\s+v2\b/i, /^GNUv?2$/i, /^GLPv2$/,
                          /\bWhatever\slicense\sPlone\sis\b/i
                         ],
      "GPL-3.0"       => [
                          /\bGPL[-|v]?3\b/i, /\bGPL\s+3/i, /\bGNU\s+GPL\b/i,
                          /\bGNU\s+GENERAL\s+PUBLIC\s+License\s+[v]?3\b/i,
                          /\bGNU\sPublic\sLicense\sv?3\.0\b/i,
                          /\bGNU\s+PUBLIC\s+LICENSE\s+v?3\b/i,
                          /\bGnu\sPublic\sLicense\sversion\s3\b/i,
                          /\bGeneral\sPublice?\sLicense\sversion\s3\b/i,
                          /\bGNU\s+PUBLIC\s+v3\+?\b/i,
                          /\bGNU\sPublic\sGeneral\sLicense\b/i,
                          /\b[\(]?GPL[\)]?\b/i, /\bGNU\s+PL\s+[v]?3\b/i,
                          /\bGLPv3\b/i, /\bGNU3\b/i, /GPvL3/i,
                          /\bGNU\sGLP\sv?3\b/i
                         ],
      "ISC"           => [/\bISC\s+LICENSE\b/i, /\b[\(]?ISCL[\)]?\b/i, /\bISC\b/i,
                          /\^ICS$/i],
      "JSON"          => [/\bJSON\s+LICENSE\b/i],
      "LGPL-2.0"      => [/\bLGPL[-|v]?2\b/i, /\bLGPL[-|v]?2\.0\b/i],
      "LGPL-2.1"      => [/\bLGPL[-|v]?2\.1\b/i],
      "LGPL-3.0"      => [/\bLGPL[-|v]?3\b/i, /\bLGPL[-|v]?3\.0\b/i,
                          /\b[\(]?LGPL[\)]?/i, /\bLGPLv3\+\b/i, /^LGBL$/i,
                          /\bLPGL[\,|3]?\b/i, /\bLGLP[\s|-|v]?3\.0\b/i,
                          /^LPLv3$/,
                          /\bLESSER\s+GENERAL\s+PUBLIC\s+License\s+[v]?3\b/i,
                          /\bLesser\sGNU\sPublic\sLicense\b/i,
                          /^http:\/\/www\.gnu\.org\/copyleft\/lesser.html$/i
                         ],
      "MirOS"         => [/\bMirOS\b/i],
      "MIT"           => [/\bMIT\s+LICEN[S|C]E\b/i, /\bMIT\b/i, /\bEXPAT\b/i, /^MIT./i],
      "MPL-1.0"       => [/\bMPL[-|v]?1\b/i, /\bMPL[-|v]?1\.0\b/i],
      "MPL-1.1"       => [/\bMPL[-|v]?1\.1\b/i],
      "MPL-2.0"       => [
                          /\bMPL[-|v]?2\b/i, /\bMPL[-|v]?2\.0\b/i,
                          /\bMOZILLA\s+PUBLIC\s+LICENSE\s+2\.0\b/i,
                          /\bMOZILLA\s+PUBLIC\s+LICENSE[,]?\s+version\s+2\.0\b/i,
                          /\bMozilla\sPublic\sLicense\b/i,
                          /\b[\(]?MPL\s+2\.0[\)]?\b/i, /\b[\(]?MPL[\)]?\b/i
                         ],
      "MS-PL"         => [/\bMS-?PL\b/i],
      "MS-RL"         => [/\bMS-?RL\b/i, /\bMSR\-LA\b/i],
      "NCSA"          => [/^NCSA$/, /\bNCSA\s+License\b/i,
                          /\bIllinois\/NCSA\sOpen\sSource\b/i],
      "NGPL"          => [/\bNGPL\b/i],
      "NPOSL-3.0"     => [/\bNPOSL[-|_|\s]?3\.0\b/i],
      "OFL-1.0"       => [/\bOFL[-|v]?1\.0\b/i, /\bOFL[-|v]?1\b/i, /\bSIL\s+OFL\s+1\.0\b/i],
      "OFL-1.1"       => [/\bOFL[-|v]?1\.1\b/i, /\bSIL\s+OFL\s+1\.1\b/i],
      "OSL-1.0"       => [/\bOSL[-|v]?1\b/i, /\b\OSL[-|v]?1\.0\b/i],
      "OSL-2.0"       => [/\bOSL[-|v]?2\b/i, /\bOSL[-|v]2\.0?\b/i],
      "OSL-2.1"       => [/\bOSL[-|v]?2\.1\b/i],
      "OSL-3.0"       => [/\bOSL[-|v]?3/i, /\bOSL[-|v]?3\.0\b/i],
      "PostgreSQL"    => [/\bPostgreSQL\b/i],
      "Public Domain" => [/\bPublic\s+Domain\b/i],
      "Python-2.0"    => [
                          /\bPython[-|v]?2\b/i, /\bPython[-|v]?2\.0\b/i,
                          /\bPSF2\b/i, /\bPSFL\b/i, /\bPSF\b/i,
                          /\bPython\s+Software\s+Foundation\b/i,
                          /\bPython\b/i, /\bPSL\b/i,
                          /^http:\/\/www\.opensource\.org\/licenses\/PythonSoftFoundation\.php$/i
                         ],
      "RPL-1.1"       => [/\bRPL[-|v]?1\b/i, /\bRPL[-|v]?1\.1\b/i],
      "RPL-1.5"       => [
                          /\bRPL[-|v]?1\.5\b/i, /^RPL$/,
                          /\bhttps?:\/\/www\.opensource\.org\/licenses\/rpl\.php\b/i
                         ],
      "QPL-1.0"       => [/\bQPL[_|-|\s]?1\.0\b/i,
                          /\bQT\sPublic\sLicen[c|s]e\b/i,
                          /\bPyQ\sGeneral\sLicense\b/i],
      "Sleepycat"     => [/\bSleepyCat\b/i],
      "W3C"           => [/\bW3C\b/i],
      "OpenSSL"       => [/\bOPENSSL\b/i],
      "Unlicense"     => [
                          /\bUNLICENSE\b/i, /^Unlicensed$/i, /\bNO\s+LICEN[C|S]E\b/i,
                          /^Opensourse$/i, /^go\sfor\sit/i, /^Undecided$/i
                         ],
      "WTFPL"         => [
                          /\bWTF[P|G]L\b/i, /\bWTFPL[-|v]?2\b/i, /^WTFL$/i,
                          /\bDo\s+whatever\s+you\s+want\b/i, /\bDWTFYW\b/i,
                          /\bDo\s+What\s+the\s+Fuck\s+You\s+Want\b/i, /^DWTFYWT$/i
                         ],
      "WXwindows"     => [/^wxWindows$/i, /\bwxWINDOWS\s+LIBRARY\sLICEN[C|S]E\b/i],
      "X11"           => [/\bX11\b/i],
      "ZPL-1.1"       => [/\bZPL[-|v]?1\b/i, /\bZPL[-|v]?1\.1\b/i],
      "ZPL-2.1"       => [
                          /\bZPL[-|v]?2\b/i, /\bZPL[-|v]?2\.1\b/i,
                          /\bZPL\s+2\.1\b/i, /\bZOPE\s+PUBLIC\s+LICENSE\b/i,
                          /\bZPL\b/i
                         ],
      "ZLIB"          => [/\bZLIB\b/i],
      "zlib-acknowledgement" => [/\bZLIB\/LIBPNG\b/i]
    }
  end

end

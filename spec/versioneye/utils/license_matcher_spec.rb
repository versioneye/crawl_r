require 'spec_helper'
require 'httparty'

describe LicenseMatcher do
  
  let(:corpus_path){ 'data/licenses/texts/plain' }
  let(:lic_matcher){ LicenseMatcher.new(corpus_path) }
  let(:mit_txt){ File.read("#{corpus_path}/MIT") }
  let(:pg_txt){ File.read("#{corpus_path}/PostgreSQL") }
  let(:lgpl_txt){ File.read("#{corpus_path}/LGPL-2.0") }
  let(:bsd3_txt){ File.read("#{corpus_path}/BSD-3") }
  let(:dotnet_txt){ File.read('data/custom_licenses/msl_dotnet') }

  before do
    FakeWeb.allow_net_connect = %r[^https?://localhost]
  end

  it "calculates correct COS similarity" do
    mat1 = NArray[*[2, 1, 0, 2, 0, 1, 1, 1]]
    mat2 = NArray[*[2, 1, 1, 1, 1, 0, 1, 1]]
    expect(lic_matcher.cos_sim(mat1, mat2)).to be_between(0.82,0.83).inclusive
  end

  it "finds correct matches for text files" do
    expect( lic_matcher.match_text(mit_txt).first.first ).to eq("MIT")
    expect( lic_matcher.match_text(pg_txt).first.first ).to eq('PostgreSQL')
    expect( lic_matcher.match_text(lgpl_txt).first.first ).to eq('LGPL-2.0')
    expect( lic_matcher.match_text(pg_txt).first.first ).to eq('PostgreSQL')
    expect( lic_matcher.match_text(bsd3_txt).first.first ).to eq('BSD-3')
    expect( lic_matcher.match_text(dotnet_txt).first.first ).to eq('msl_dotnet')
  end

  let(:min_score){ 0.5 }
  let(:spec_path){ 'spec/fixtures/files/licenses' }
  let(:mit_html){ File.read "#{spec_path}/mit.htm" }
  let(:apache_html){File.read "#{spec_path}/apache2.html" }
  let(:dotnet_html){ File.read "#{spec_path}/ms.htm" }
  let(:bsd3_html){ File.read "#{spec_path}/bsd3.html" }
  let(:apache_aws){File.read "#{spec_path}/apache_aws.html"}
  let(:apache_plex){ File.read "#{spec_path}/apache_plex.html"}
  let(:bsd_fparsec){ File.read "#{spec_path}/bsd_fparsec.html"}
  let(:mit_ooi){ File.read "#{spec_path}/mit_ooi.html" }
  let(:mit_bb){ File.read "#{spec_path}/mit_bb.html" }
  let(:mspl_ooi){ File.read "#{spec_path}/mspl_ooi.html" }
  let(:cpol){File.read "#{spec_path}/cpol.html"}

  it "finds correct matches for html files" do

    expect( lic_matcher.match_html(mit_html).first.first ).to eq('MIT')
    expect( lic_matcher.match_html(apache_html).first.first ).to eq('Apache-2.0')
    expect( lic_matcher.match_html(dotnet_html).first.first ).to eq('msl_dotnet')
    expect( lic_matcher.match_html(bsd3_html).first.first ).to eq('BSD-4')

    #how it handles noisy pages
    spdx_id, score = lic_matcher.match_html(apache_aws).first
    expect( spdx_id ).to eq('Apache-2.0')
    expect( score ).to be > min_score

    spdx_id, score = lic_matcher.match_html(apache_plex).first 
    expect( spdx_id ).to eq('Apache-2.0')
    expect( score ).to be > min_score

    spdx_id, score = lic_matcher.match_html(bsd_fparsec).first
    expect( spdx_id ).to eq('BSD-3')
    expect( score ).to be > min_score

    spdx_id, score = lic_matcher.match_html(mit_ooi).first 
    expect( spdx_id ).to eq('MIT')
    expect( score ).to be > min_score

    spdx_id, score = lic_matcher.match_html(mit_bb).first
    expect( spdx_id ).to eq('MIT')
    expect( score ).to be > min_score

    expect( lic_matcher.match_html(mspl_ooi).first.first ).to eq('MS-PL')

    spdx_id, score = lic_matcher.match_html(cpol).first
    expect( spdx_id ).to eq('CPOL-1.02')
    expect( score ).to be > min_score 
  end

  it "matches all the license files in the corpuse correctly" do
    lic_matcher.licenses.each do |lic_id|
      next if lic_id == 'msl_dotnet' or lic_id == 'CPOL-1.02'

      lic_txt = File.read "#{corpus_path}/#{lic_id}"

      res = lic_matcher.match_text(lic_txt)
      p "#{lic_id} => #{res} "
      expect(res).not_to be_nil
      expect(res.first.first).to eq(lic_id)
    end
  end

# COMMENT OUT WHEN DEVELOPING  
#  it "matches all the MIT urls as MIT license" do
#    File.foreach("#{spec_path}/mit_urls.txt") do |mit_url|
#      mit_url.to_s.gsub!(/\s+/, '')
#      p "URL: #{mit_url}"
#
#      res = HTTParty.get(mit_url)
#      expect( res.code ).to eq(200)
#      expect(lic_matcher.match_text(res.body).first.first ).to eq('MIT')
#    end
#  end

  let(:aal_url){ "https://opensource.org/licenses/AAL"  }
  let(:apache1){ "https://opensource.org/licenses/Apache-1.1" }
  let(:apache2){ "https://www.apache.org/licenses/LICENSE-2.0" }
  let(:bsd2){ "https://opensource.org/licenses/BSD-2-Clause" }
  let(:bsd3){ "https://opensource.org/licenses/BSD-3-Clause" }
	let(:gpl3){ "https://www.gnu.org/licenses/gpl-3.0.txt" }

  it "build license url index from license.json file" do
    url_doc = lic_matcher.read_json_file "#{spec_path}/licenses.json"
    expect( url_doc ).not_to be_nil

    url_index = lic_matcher.read_license_url_index url_doc
    expect( url_index ).not_to be_nil
    expect( url_index[aal_url] ).to eq('AAL')
		expect( url_index[apache1] ).to eq('Apache-1.1')
		expect( url_index[apache2] ).to eq('Apache-2.0')
		expect( url_index[bsd2] ).to eq('BSD-2')
		expect( url_index[bsd3] ).to eq('BSD-3')
		expect( url_index[gpl3] ).to eq('GPL-3.0')
  end

	it "matches saved URL with SPDX url" do
		expect( lic_matcher.match_url(aal_url).first ).to eq('AAL')
		expect( lic_matcher.match_url(apache1).first ).to eq('Apache-1.1')
		expect( lic_matcher.match_url(apache2).first ).to eq('Apache-2.0')
		expect( lic_matcher.match_url(bsd2).first).to eq('BSD-2')
		expect( lic_matcher.match_url(bsd3).first).to eq('BSD-3')
		expect( lic_matcher.match_url(gpl3).first ).to eq('GPL-3.0')
	end
end

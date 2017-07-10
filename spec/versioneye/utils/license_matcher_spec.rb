require 'spec_helper'
require 'httparty'

describe LicenseMatcher do
  lic_matcher = LicenseMatcher.new
  let(:licenses_json_path){'data/spdx_licenses/licenses.json'}
  let(:corpus_path){ 'data/spdx_licenses/plain' }
  let(:spec_path){ 'spec/fixtures/files/licenses' }
  let(:filenames){ Dir.entries('data/spdx_licenses/plain').to_a.delete_if {|f| /\.+/.match?(f)} }

  let(:mit_txt){ File.read("#{corpus_path}/MIT") }
  let(:pg_txt){ File.read("#{corpus_path}/PostgreSQL") }
  let(:lgpl_txt){ File.read("#{corpus_path}/LGPL-2.0") }
  let(:bsd3_txt){ File.read("#{corpus_path}/BSD-3-Clause") }
  let(:dotnet_txt){ File.read('data/custom_licenses/ms_dotnet') }
  let(:mit_issue11){ File.read("#{spec_path}/mit_issue11.txt")}

  it "finds correct matches for text files" do
    expect( lic_matcher.match_text(mit_txt).first.first ).to eq("mit")
    expect( lic_matcher.match_text(pg_txt).first.first ).to eq('postgresql')
    expect( lic_matcher.match_text(lgpl_txt).first.first ).to eq('lgpl-2.0')
    expect( lic_matcher.match_text(pg_txt).first.first ).to eq('postgresql')
    expect( lic_matcher.match_text(bsd3_txt).first.first ).to eq('bsd-3-clause')
    expect( lic_matcher.match_text(dotnet_txt).first.first ).to eq('ms_dotnet')
  end

  it "matches MIT license so it could fix the issue#11" do
    res = lic_matcher.match_text(mit_issue11)
    expect( res.size ).to eq(3)

    spdx_id, score = res.first
    expect( spdx_id ).to eq("mit")
    expect( score ).to be > 0.9
  end

  let(:min_score){ 0.5 }
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

    expect( lic_matcher.match_html(mit_html).first.first ).to eq('mit')
    expect( lic_matcher.match_html(apache_html).first.first ).to eq('apache-2.0')
    expect( lic_matcher.match_html(dotnet_html).first.first ).to eq('ms_dotnet')
    expect( lic_matcher.match_html(bsd3_html).first.first ).to eq('bsd-3-clear')

    #how it handles noisy pages
    spdx_id, score = lic_matcher.match_html(apache_aws).first
    expect( spdx_id ).to eq('apache-2.0')
    expect( score ).to be > min_score

    spdx_id, score = lic_matcher.match_html(apache_plex).first
    expect( spdx_id ).to eq('apache-2.0')
    expect( score ).to be > min_score

    spdx_id, score = lic_matcher.match_html(bsd_fparsec).first
    expect( spdx_id ).to eq('bsd-3-clear')
    expect( score ).to be > min_score

    spdx_id, score = lic_matcher.match_html(mit_ooi).first
    expect( spdx_id ).to eq('mit')
    expect( score ).to be > min_score

    spdx_id, score = lic_matcher.match_html(mit_bb).first
    expect( spdx_id ).to eq('mit')
    expect( score ).to be > min_score

    expect( lic_matcher.match_html(mspl_ooi).first.first ).to eq('ms-pl')

    spdx_id, score = lic_matcher.match_html(cpol).first
    expect( spdx_id ).to eq('cpol-1.02')
    expect( score ).to be > min_score
  end

  it "matches all the license files in the corpuse correctly" do

    filenames.each do |lic_name|
      lic_id = lic_name.downcase
      next if lic_id == 'ms_dotnet' or lic_id == 'cpol-1.02'


      lic_txt = File.read "#{corpus_path}/#{lic_name}"

      res = lic_matcher.match_text(lic_txt)
      p "#{lic_name} => #{res} "
      expect(res).not_to be_nil
      expect(res.empty? ).to be_falsey
      expect(res.first.first).to eq(lic_id)
    end
  end

  let(:aal_url){ "https://opensource.org/licenses/AAL"  }
  let(:apache1){ "https://opensource.org/licenses/Apache-1.1" }
  let(:apache2){ "https://www.apache.org/licenses/LICENSE-2.0" }
  let(:bsd2){ "https://opensource.org/licenses/BSD-2-Clause" }
  let(:bsd3){ "https://opensource.org/licenses/BSD-3-Clause" }
	let(:gpl3){ "https://www.gnu.org/licenses/gpl-3.0.txt" }

  it "build license url index from license.json file" do
    url_doc = lic_matcher.read_json_file licenses_json_path
    expect( url_doc ).not_to be_nil

    url_index = lic_matcher.read_license_url_index url_doc
    expect( url_index ).not_to be_nil
    expect( url_index[aal_url] ).to eq('aal')
		expect( url_index[apache1] ).to eq('apache-1.1')
		expect( url_index[apache2] ).to eq('apache-2.0')
    expect( url_index[bsd2] ).to eq('bsd-2-clause')
		expect( url_index[bsd3] ).to eq('bsd-3-clause')
		expect( url_index[gpl3] ).to eq('gpl-3.0')
  end

	it "matches saved URL with SPDX url" do
		expect( lic_matcher.match_url(aal_url).first ).to eq('aal')
		expect( lic_matcher.match_url(apache1).first ).to eq('apache-1.1')
		expect( lic_matcher.match_url(apache2).first ).to eq('apache-2.0')
		expect( lic_matcher.match_url(bsd2).first).to eq('bsd-2-clause')
		expect( lic_matcher.match_url(bsd3).first).to eq('bsd-3-clause')
		expect( lic_matcher.match_url(gpl3).first ).to eq('gpl-3.0')
	end

  it "matches chooselicense urls to spdx_Id" do
    expect(lic_matcher.match_url('https://www.choosealicense.com/licenses/apache-2.0/')[0]).to eq('apache-2.0')
    expect(lic_matcher.match_url('http://choosealicense.com/licenses/agpl-3.0/')[0]).to eq('agpl-3.0')
    expect(lic_matcher.match_url('https://choosealicense.com/licenses/cc0-1.0')[0]).to eq('cc0-1.0')
    expect(lic_matcher.match_url('https://choosealicense.com/licenses/mit/')[0]).to eq('mit')
  end

  it "matches cc-commons urls to spdx-id" do
    expect(lic_matcher.match_url('https://creativecommons.org/licenses/by/4.0')[0]).to eq('cc-by-4.0')
    expect(lic_matcher.match_url('https://creativecommons.org/licenses/by/4.0/')[0]).to eq('cc-by-4.0')
    expect(lic_matcher.match_url('https://creativecommons.org/licenses/by-sa/4.0/')[0]).to eq('cc-by-sa-4.0')
    expect(lic_matcher.match_url('https://creativecommons.org/licenses/by-nc/4.0/')[0]).to eq('cc-by-nc-4.0')
    expect(lic_matcher.match_url('https://creativecommons.org/licenses/by-nd/4.0/')[0]).to eq('cc-by-nd-4.0')
  end
end

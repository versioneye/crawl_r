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

  it "finds correct matches for text files" do
    expect( lic_matcher.match_text(mit_txt).first.first ).to eq("MIT")
    expect( lic_matcher.match_text(pg_txt).first.first ).to eq('PostgreSQL')
    expect( lic_matcher.match_text(lgpl_txt).first.first ).to eq('LGPL-2.0')
    expect( lic_matcher.match_text(pg_txt).first.first ).to eq('PostgreSQL')
    expect( lic_matcher.match_text(bsd3_txt).first.first ).to eq('BSD-3')
    expect( lic_matcher.match_text(dotnet_txt).first.first ).to eq('msl_dotnet')
  end

  let(:min_score){ 0.4 }
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

end

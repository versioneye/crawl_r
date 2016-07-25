require 'spec_helper'

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

  #TODO: run test over all the corpus files

  let(:spec_path){ 'spec/fixtures/files/licenses' }
  let(:mit_html){ File.read "#{spec_path}/mit.htm" }
  let(:apache_html){File.read "#{spec_path}/apache2.html" }
  let(:dotnet_html){ File.read "#{spec_path}/ms.htm" }
  let(:bsd3_html){ File.read "#{spec_path}/bsd3.html" }
  let(:apache_aws){File.read "#{spec_path}/apache_aws.html"}
  let(:apache_plex){ File.read "#{spec_path}/apache_plex.html"}
  let(:bsd_fparsec){ File.read "#{spec_path}/bsd_fparsec.html"}

  it "finds correct matches for html files" do

    expect( lic_matcher.match_html(mit_html).first.first ).to eq('MIT')
    expect( lic_matcher.match_html(apache_html).first.first ).to eq('Apache-2.0')
    expect( lic_matcher.match_html(dotnet_html).first.first ).to eq('msl_dotnet')
    expect( lic_matcher.match_html(bsd3_html).first.first ).to eq('BSD-4')

    #how it handles noisy pages
    expect( lic_matcher.match_html(apache_aws).first.first ).to eq('Apache-2.0')
    expect( lic_matcher.match_html(apache_plex).first.first ).to eq('Apache-2.0')
    expect( lic_matcher.match_html(bsd_fparsec).first.first ).to eq('BSD-3')

  end
end

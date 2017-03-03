require 'spec_helper'
require 'json'

describe LicenseMatcher do
  lm = LicenseMatcher.new
  let(:json_file_path){ 'data/spdx_licenses/licenses.json' }
  let(:json_licenses){ JSON.parse(File.read(json_file_path)) }

  it "rules are matching data in the licenses.json file" do
    json_licenses.each do |lic|
      spdx_id = lic["id"].downcase
      p "#-- #{lic["id"]} - #{lic['name']}"
      expect(lm.match_rules(lic["id"])[0][0]).to eq(spdx_id)
      expect(lm.match_rules("#{lic['id']} yyy")[0][0])

      #-- does it detect license name?
      expect(lm.match_rules(lic["name"])[0][0]).to eq(spdx_id)
      expect(lm.match_rules("xxx #{lic['name']} zzz")[0][0]).to eq(spdx_id)

      #-- does it match urls
      lic["links"].to_a.each do |link|
        p "    #-- url: #{link["url"]}"
        res = lm.match_rules(link["url"])
        expect(res).not_to be_empty
        expect(res[0][0]).to eq(spdx_id)
        expect(lm.match_rules("aaaa " + link["url"] + " vnvnnv")[0][0]).to eq(spdx_id)
      end

      #-- does it match urls of license text
      lic["text"].to_a.each do |link|
        p "    #-- url: #{link["url"]}"
        expect(lm.match_rules(link["url"])[0][0]).to eq(spdx_id)
        expect(lm.match_rules("aaaa " + link["url"] + " vnvnnv")[0][0]).to eq(spdx_id)
      end
    end
  end

end

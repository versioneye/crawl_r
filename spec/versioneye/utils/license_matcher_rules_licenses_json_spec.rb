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
    end
  end

end

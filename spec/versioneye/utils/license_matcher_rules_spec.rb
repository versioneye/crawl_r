require 'spec_helper'

describe LicenseMatcher do
  let(:lic_matcher){ LicenseMatcher.new }
  let(:corpus_path){ 'data/licenses/texts/plain' }

  describe "match_rules" do
    it "matches noisy MIT license names" do
      expect( lic_matcher.match_rules('Original Cutadapt code is under MIT license;') ).to eq([['MIT', 1.0]])
    end

    it "matches GPL2 rules" do
      expect( lic_matcher.match_rules('GNU GPL v2 or later, plus transitive 12 m') ).to eq([['GPL-2.0', 1.0]])
    end

    it "matches AGPL-3 rules" do
      expect( lic_matcher.match_rules('GNU Affero General Public License v3 or later (AGPLv3+)') ).to eq([['AGPL-3.0', 1.0]])
    end
  end

end

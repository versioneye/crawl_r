require 'spec_helper'

describe LicenseMatcher do
  #let(:lic_matcher){ LicenseMatcher.new }
  lic_matcher = LicenseMatcher.new #initialization is slow, just init once

  describe "match_rules" do
    it "matches AAL" do
      expect(lic_matcher.match_rules('AAL')).to eq([['AAL', 1.0]]);
      expect(lic_matcher.match_rules('It uses AAL license for source code')).to eq([['AAL', 1.0]])
      expect(lic_matcher.match_rules('(C) Attribution Assurance License 2011')).to eq([['AAL', 1.0]])
    end
   
    it "matches AFL" do
      expect(lic_matcher.match_rules('AFL-1.1')).to eq([['AFL-1.1', 1.0]])
      expect(lic_matcher.match_rules('Released under AFLv1 license')).to eq([['AFL-1.1', 1.0]])
      expect(lic_matcher.match_rules('AFLv1.2 license')).to eq([['AFL-1.2', 1.0]])
      expect(lic_matcher.match_rules('licensed under AFL-1.2 License')).to eq([['AFL-1.2', 1.0]])
      expect(lic_matcher.match_rules('AFL-2.0')).to eq([['AFL-2.0', 1.0]])
      expect(lic_matcher.match_rules('licensed as AFLv2 license')).to eq([['AFL-2.0', 1.0]])
      expect(lic_matcher.match_rules('AFL-2.1')).to eq([['AFL-2.1', 1.0]])
      expect(lic_matcher.match_rules('released under AFLv2.1 lic')).to eq([['AFL-2.1', 1.0]])
      expect(lic_matcher.match_rules('AFLv3.0')).to eq([['AFL-3.0', 1.0]])
      expect(lic_matcher.match_rules('uses AFLv3.0 license')).to eq([['AFL-3.0', 1.0]])
      expect(lic_matcher.match_rules('Academic Free License')).to eq([['AFL-3.0', 1.0]])
    end

    it "matches AGPL licenses" do
      expect(lic_matcher.match_rules('licensed under AGPL')).to eq([['AGPL-1.0', 1.0]])
      expect(lic_matcher.match_rules('AGPLv1')).to eq([['AGPL-1.0', 1.0]])
      expect(lic_matcher.match_rules('Affero General Public license 1')).to eq([['AGPL-1.0', 1.0]])

      expect(lic_matcher.match_rules('AGPL-3')).to eq([['AGPL-3.0', 1.0]])
      expect(lic_matcher.match_rules('It uses AGPLv3.0')).to eq([['AGPL-3.0', 1.0]])
      expect(lic_matcher.match_rules('GNU Affero General Public License v3 or later (AGPLv3+)') ).to eq([['AGPL-3.0', 1.0]])

    end

    it "matches APACHE licenses" do
      expect(lic_matcher.match_rules('APACHEv1')).to eq([['Apache-1.0', 1.0]])
      expect(lic_matcher.match_rules('Released under Apache-1.0')).to eq([['Apache-1.0', 1.0]])
      expect(lic_matcher.match_rules('uses Apache 1.0 license')).to eq([['Apache-1.0', 1.0]])

      expect(lic_matcher.match_rules('APACHE-1.1')).to eq([['Apache-1.1', 1.0]])
      expect(lic_matcher.match_rules('Apache v1.1 license')).to eq([['Apache-1.1', 1.0]])
      expect(lic_matcher.match_rules('uses Apache-1.1 lic')).to eq([['Apache-1.1', 1.0]])
    end

    it "matches noisy MIT license names" do
      expect( lic_matcher.match_rules('Original Cutadapt code is under MIT license;') ).to eq([['MIT', 1.0]])
    end

    it "matches GPL2 rules" do
      expect( lic_matcher.match_rules('GNU GPL v2 or later, plus transitive 12 m') ).to eq([['GPL-2.0', 1.0]])
    end

  end

end

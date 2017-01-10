require 'spec_helper'

describe LicenseMatcher do
  #let(:lic_matcher){ LicenseMatcher.new }
  lic_matcher = LicenseMatcher.new #initialization is slow, just init once

  describe "match_rules" do
    it "matches AAL" do
      expect(lic_matcher.match_rules('AAL').first.first).to eq('AAL');
      expect(lic_matcher.match_rules('It uses AAL license for source code').first.first).to eq('AAL')
      expect(lic_matcher.match_rules('(C) Attribution Assurance License 2011').first.first).to eq('AAL')
    end
   
    it "matches AFL" do
      expect(lic_matcher.match_rules('AFL-1.1').first.first).to eq('AFL-1.1')
      expect(lic_matcher.match_rules('Released under AFLv1 license').first.first).to eq('AFL-1.1')
      expect(lic_matcher.match_rules('AFLv1.2 license').first.first).to eq('AFL-1.2')
      expect(lic_matcher.match_rules('licensed under AFL-1.2 License').first.first).to eq('AFL-1.2')
      expect(lic_matcher.match_rules('AFL-2.0').first.first).to eq('AFL-2.0')
      expect(lic_matcher.match_rules('licensed as AFLv2 license').first.first).to eq('AFL-2.0')
      expect(lic_matcher.match_rules('AFL-2.1').first.first).to eq('AFL-2.1')
      expect(lic_matcher.match_rules('released under AFLv2.1 lic').first.first).to eq('AFL-2.1')
      expect(lic_matcher.match_rules('AFLv3.0').first.first).to eq('AFL-3.0')
      expect(lic_matcher.match_rules('uses AFLv3.0 license').first.first).to eq('AFL-3.0')
      expect(lic_matcher.match_rules('Academic Free License').first.first).to eq('AFL-3.0')
    end

    it "matches AGPL licenses" do
      expect(lic_matcher.match_rules('licensed under AGPL').first.first).to eq('AGPL-1.0')
      expect(lic_matcher.match_rules('AGPLv1').first.first).to eq('AGPL-1.0')
      expect(lic_matcher.match_rules('Affero General Public license 1').first.first).to eq('AGPL-1.0')

      expect(lic_matcher.match_rules('AGPL-3').first.first).to eq('AGPL-3.0')
      expect(lic_matcher.match_rules('It uses AGPLv3.0').first.first).to eq('AGPL-3.0')
      expect(lic_matcher.match_rules('GNU Affero General Public License v3 or later (AGPLv3+)').first.first ).to eq('AGPL-3.0')

    end

    it "matches APACHE licenses" do
      expect(lic_matcher.match_rules('APACHEv1').first.first ).to eq('Apache-1.0')
      expect(lic_matcher.match_rules('Lic as APACHE-V1').first.first).to eq('Apache-1.0')
      expect(lic_matcher.match_rules('APacheV1 is +100').first.first).to eq('Apache-1.0')
      expect(lic_matcher.match_rules('Released under Apache-1.0').first.first).to eq('Apache-1.0')
      expect(lic_matcher.match_rules('uses Apache 1.0 license').first.first).to eq('Apache-1.0')

      expect(lic_matcher.match_rules('APACHE-1.1').first.first).to eq('Apache-1.1')
      expect(lic_matcher.match_rules('Apache v1.1 license').first.first).to eq('Apache-1.1')
      expect(lic_matcher.match_rules('uses Apache-1.1 lic').first.first).to eq('Apache-1.1')

      expect(lic_matcher.match_rules('APACHEv2').first.first).to eq('Apache-2.0')
      expect(lic_matcher.match_rules('APACHE-2').first.first).to eq('Apache-2.0')
      expect(lic_matcher.match_rules('Apache v2').first.first).to eq('Apache-2.0')
      expect(lic_matcher.match_rules('uses Apache 2.0').first.first).to eq('Apache-2.0')
      expect(lic_matcher.match_rules('Apache 2 is it').first.first).to eq('Apache-2.0')
      expect(lic_matcher.match_rules('Apache license version 2.0').first.first).to eq('Apache-2.0')
    end

    it "matches APL licenses" do
      expect(lic_matcher.match_rules('APLv1').first.first).to eq('APL-1.0')
      expect(lic_matcher.match_rules('APL-1').first.first).to eq('APL-1.0')
      expect(lic_matcher.match_rules('APL-v1').first.first).to eq('APL-1.0')
      expect(lic_matcher.match_rules('lic APLv1 lic').first.first).to eq('APL-1.0')
      expect(lic_matcher.match_rules('APL v1').first.first).to eq('APL-1.0')
      expect(lic_matcher.match_rules('APL 1.0').first.first).to eq('APL-1.0')
    end

    it "matches APLS-1.0 licenses" do
      expect(lic_matcher.match_rules('APSLv1.0').first.first).to eq('APSL-1.0')
      expect(lic_matcher.match_rules('APSL 1.0').first.first).to eq('APSL-1.0')
      expect(lic_matcher.match_rules('lic APSL-1.0 lic').first.first).to eq('APSL-1.0')
      expect(lic_matcher.match_rules('lic APSL-v1.0').first.first).to eq('APSL-1.0')

      expect(lic_matcher.match_rules('APSLv1')[0][0]).to eq('APSL-1.0')
      expect(lic_matcher.match_rules('APSL-v1')[0][0]).to eq('APSL-1.0')
      expect(lic_matcher.match_rules('APSL v1')[0][0]).to eq('APSL-1.0')

      expect(lic_matcher.match_rules('aa APPLE PUBLIC source')[0][0]).to eq('APSL-1.0')
    end

    it "matches APSL-1.1 licenses" do
      expect(lic_matcher.match_rules('APSLv1.1')[0][0]).to eq('APSL-1.1')
      expect(lic_matcher.match_rules('APSL 1.1')[0][0]).to eq('APSL-1.1')
      expect(lic_matcher.match_rules('APSL v1.1')[0][0]).to eq('APSL-1.1')
      expect(lic_matcher.match_rules('lic APSL v1.1 lic')[0][0]).to eq('APSL-1.1')
    end

    it "matches APSL-1.2 licenses" do
      expect(lic_matcher.match_rules('APSLv1.2')[0][0]).to eq('APSL-1.2')
      expect(lic_matcher.match_rules('APSL-1.2')[0][0]).to eq('APSL-1.2')
      expect(lic_matcher.match_rules('APSL v1.2')[0][0]).to eq('APSL-1.2')
      expect(lic_matcher.match_rules('APSL 1.2')[0][0]).to eq('APSL-1.2')
      expect(lic_matcher.match_rules('lic APSL 1.2 lic')[0][0]).to eq('APSL-1.2')
    end

    it "matches APSL-2.0 licenses" do
      expect(lic_matcher.match_rules('APSLv2.0')[0][0]).to eq('APSL-2.0')
      expect(lic_matcher.match_rules('APSL-2.0')[0][0]).to eq('APSL-2.0')
      expect(lic_matcher.match_rules('APSL v2.0')[0][0]).to eq('APSL-2.0')
      expect(lic_matcher.match_rules('APSL 2.0')[0][0]).to eq('APSL-2.0')
      expect(lic_matcher.match_rules('APSLv2')[0][0]).to eq('APSL-2.0')
      expect(lic_matcher.match_rules('APSL 2')[0][0]).to eq('APSL-2.0')
      expect(lic_matcher.match_rules('lic APSL 2.0 lic')[0][0]).to eq('APSL-2.0')
    end

    it "matches Artistic-1.0 licenses" do
      expect(lic_matcher.match_rules('ArtisticV1.0')[0][0]).to eq('Artistic-1.0')
      expect(lic_matcher.match_rules('Artistic V1.0')[0][0]).to eq('Artistic-1.0')
      expect(lic_matcher.match_rules('Artistic 1.0')[0][0]).to eq('Artistic-1.0')
    
      expect(lic_matcher.match_rules('ArtisticV1')[0][0]).to eq('Artistic-1.0')
      expect(lic_matcher.match_rules('Artistic V1')[0][0]).to eq('Artistic-1.0')
      expect(lic_matcher.match_rules('Artistic 1')[0][0]).to eq('Artistic-1.0')
      expect(lic_matcher.match_rules('uses ArtisticV1 license')[0][0]).to eq('Artistic-1.0')
    end

    it "matches Artistic-2.0 licenses" do
      expect(lic_matcher.match_rules('ArtisticV2.0')[0][0]).to eq('Artistic-2.0')
      expect(lic_matcher.match_rules('Artistic V2.0')[0][0]).to eq('Artistic-2.0')
      expect(lic_matcher.match_rules('Artistic 2.0')[0][0]).to eq('Artistic-2.0')
      expect(lic_matcher.match_rules('Artistic-2.0')[0][0]).to eq('Artistic-2.0')

      expect(lic_matcher.match_rules('ArtisticV2')[0][0]).to eq('Artistic-2.0')
      expect(lic_matcher.match_rules('Artistic 2')[0][0]).to eq('Artistic-2.0')
      expect(lic_matcher.match_rules('uses Artistic 2 license')[0][0]).to eq('Artistic-2.0')

      expect(lic_matcher.match_rules('uses Artistic License')[0][0]).to eq('Artistic-2.0')
    end

    it "matches Artistic-1.0-Perl licenses" do
      expect(lic_matcher.match_rules('Artistic-1.0-Perl')[0][0]).to eq('Artistic-1.0-Perl')
      expect(lic_matcher.match_rules('uses Artistic-1.0-Perl lic')[0][0]).to eq('Artistic-1.0-Perl')
      expect(lic_matcher.match_rules('Artistic 1.0-Perl')[0][0]).to eq('Artistic-1.0-Perl')
      expect(lic_matcher.match_rules('PerlArtistic')[0][0]).to eq('Artistic-1.0-Perl')
    end

    it "matches BeerWare" do
      expect(lic_matcher.match_rules('beerWare')[0][0]).to eq('Beerware')
      expect(lic_matcher.match_rules('Rel as Beer-Ware lic')[0][0]).to eq('Beerware')
      expect(lic_matcher.match_rules('BEER License')[0][0]).to eq('Beerware')
      expect(lic_matcher.match_rules('BEER')[0][0]).to eq('Beerware')
    end

    it "matches to BSD-2" do
      expect(lic_matcher.match_rules('BSD2')[0][0]).to eq('BSD-2-Clause')
      expect(lic_matcher.match_rules('BSD-2')[0][0]).to eq('BSD-2-Clause')
      expect(lic_matcher.match_rules('Uses BSD v2 lic')[0][0]).to eq('BSD-2-Clause')

      expect(lic_matcher.match_rules('FreeBSD')[0][0]).to eq('BSD-2-Clause')
    end

    it "matches to BSD-3" do
      expect(lic_matcher.match_rules('BSD3')[0][0]).to eq('BSD-3-Clause')
      expect(lic_matcher.match_rules('BSD v3')[0][0]).to eq('BSD-3-Clause')
      expect(lic_matcher.match_rules('BSD3')[0][0]).to eq('BSD-3-Clause')
      expect(lic_matcher.match_rules('BSD3 clause')[0][0]).to eq('BSD-3-Clause')
    end

    it "matches to BSD-4" do
      expect(lic_matcher.match_rules('BSDv4')[0][0]).to eq('BSD-4-Clause')
      expect(lic_matcher.match_rules('BSD v4')[0][0]).to eq('BSD-4-Clause')
      expect(lic_matcher.match_rules('BSD4 Clause')[0][0]).to eq('BSD-4-Clause')
      expect(lic_matcher.match_rules('BSD LISENCE')[0][0]).to eq('BSD-4-Clause')
      expect(lic_matcher.match_rules('uses BSD4 clause')[0][0]).to eq('BSD-4-Clause')
    end

    it "matches to BSL-1.0" do
      expect(lic_matcher.match_rules('BSLv1.0')[0][0]).to eq('BSL-1.0')
      expect(lic_matcher.match_rules('BSL-v1')[0][0]).to eq('BSL-1.0')
      expect(lic_matcher.match_rules('uses BSL-1.0 lic')[0][0]).to eq('BSL-1.0')
      expect(lic_matcher.match_rules('Boost License 1.0')[0][0]).to eq('BSL-1.0')
    end

    it "matches to CC0-1.0" do
      expect(lic_matcher.match_rules('CC0-1.0')[0][0]).to eq('CC0-1.0')
      expect(lic_matcher.match_rules('CC0 1.0')[0][0]).to eq('CC0-1.0')
      expect(lic_matcher.match_rules('uses CC0-v1.0 lic')[0][0]).to eq('CC0-1.0')

      expect(lic_matcher.match_rules('CC0v1')[0][0]).to eq('CC0-1.0')
      expect(lic_matcher.match_rules('CC0-v1')[0][0]).to eq('CC0-1.0')
      expect(lic_matcher.match_rules('uses CC0 v1 license')[0][0]).to eq('CC0-1.0')
    end


    it "matches noisy MIT license names" do
      expect( lic_matcher.match_rules('Original Cutadapt code is under MIT license;').first.first ).to eq('MIT')
    end

    it "matches GPL2 rules" do
      expect( lic_matcher.match_rules('GNU GPL v2 or later, plus transitive 12 m').first.first ).to eq('GPL-2.0')
    end

  end

end

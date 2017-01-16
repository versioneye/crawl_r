require 'spec_helper'

describe LicenseMatcher do
  lm = LicenseMatcher.new #initialization is slow, just init once

  describe "match_rules" do
    it "matches AAL" do
      expect(lm.match_rules('AAL').first.first).to eq('AAL');
      expect(lm.match_rules('It uses AAL license for source code').first.first).to eq('AAL')
      expect(lm.match_rules('(C) Attribution Assurance License 2011').first.first).to eq('AAL')
    end
   
    it "matches AFL" do
      expect(lm.match_rules('AFL-1.1').first.first).to eq('AFL-1.1')
      expect(lm.match_rules('Released under AFLv1 license').first.first).to eq('AFL-1.1')
      expect(lm.match_rules('AFLv1.2 license').first.first).to eq('AFL-1.2')
      expect(lm.match_rules('licensed under AFL-1.2 License').first.first).to eq('AFL-1.2')
      expect(lm.match_rules('AFL-2.0').first.first).to eq('AFL-2.0')
      expect(lm.match_rules('licensed as AFLv2 license').first.first).to eq('AFL-2.0')
      expect(lm.match_rules('AFL-2.1').first.first).to eq('AFL-2.1')
      expect(lm.match_rules('released under AFLv2.1 lic').first.first).to eq('AFL-2.1')
      expect(lm.match_rules('AFLv3.0').first.first).to eq('AFL-3.0')
      expect(lm.match_rules('uses AFLv3.0 license').first.first).to eq('AFL-3.0')
      expect(lm.match_rules('Academic Free License').first.first).to eq('AFL-3.0')

      expect(lm.match_rules('AFL')[0][0]).to eq('AFL-3.0')
    end

    it "matches AGPL licenses" do
      expect(lm.match_rules('licensed under AGPL').first.first).to eq('AGPL-1.0')
      expect(lm.match_rules('AGPLv1').first.first).to eq('AGPL-1.0')
      expect(lm.match_rules('Affero General Public license 1').first.first).to eq('AGPL-1.0')

      expect(lm.match_rules('AGPL-3').first.first).to eq('AGPL-3.0')
      expect(lm.match_rules('It uses AGPLv3.0').first.first).to eq('AGPL-3.0')
      expect(lm.match_rules('GNU Affero General Public License v3 or later (AGPLv3+)').first.first).to eq('AGPL-3.0')

      expect(lm.match_rules('Affero General Public License, version 3.0')[0][0]).to eq('AGPL-3.0')
      expect(lm.match_rules('GNU Affero General Public License, version 3')[0][0]).to eq('AGPL-3.0')
      expect(lm.match_rules('GNU AGPL v3')[0][0]).to eq('AGPL-3.0')
      expect(lm.match_rules('AGPL v3+')[0][0]).to eq('AGPL-3.0')

      expect(lm.match_rules('Lesser Affero General Public License v3')[0][0]).to eq('AGPL-3.0')
      expect(lm.match_rules('https://gnu.org/licenses/agpl.html')[0][0]).to eq('AGPL-3.0')
      expect(lm.match_rules('Affero General Public License')[0][0]).to eq('AGPL-3.0')
      expect(lm.match_rules('Software license AGPL version 3. ')[0][0]).to eq('AGPL-3.0')
      expect(lm.match_rules('GNU AFFERO 3')[0][0]).to eq('AGPL-3.0')
    end

    it "matches Aladdin rules" do
      expect(lm.match_rules('AFPL')[0][0]).to eq('Aladdin')
      expect(lm.match_rules('(AFPL)')[0][0]).to eq('Aladdin')

      expect(lm.match_rules('Aladdin Free Public License')[0][0]).to eq('Aladdin')
    end

    it "matches Amazon rules" do
      expect(lm.match_rules('Amazon Software License')[0][0]).to eq('Amazon')
    end

    it "matches APACHE licenses" do
      expect(lm.match_rules('APACHEv1').first.first ).to eq('Apache-1.0')
      expect(lm.match_rules('Lic as APACHE-V1').first.first).to eq('Apache-1.0')
      expect(lm.match_rules('APacheV1 is +100').first.first).to eq('Apache-1.0')
      expect(lm.match_rules('Released under Apache-1.0').first.first).to eq('Apache-1.0')
      expect(lm.match_rules('uses Apache 1.0 license').first.first).to eq('Apache-1.0')

      expect(lm.match_rules('APACHE-1.1').first.first).to eq('Apache-1.1')
      expect(lm.match_rules('Apache v1.1 license').first.first).to eq('Apache-1.1')
      expect(lm.match_rules('uses Apache-1.1 lic').first.first).to eq('Apache-1.1')

      expect(lm.match_rules('APACHEv2').first.first).to eq('Apache-2.0')
      expect(lm.match_rules('APACHE-2').first.first).to eq('Apache-2.0')
      expect(lm.match_rules('Apache v2').first.first).to eq('Apache-2.0')
      expect(lm.match_rules('uses Apache 2.0').first.first).to eq('Apache-2.0')
      expect(lm.match_rules('Apache 2 is it').first.first).to eq('Apache-2.0')
      expect(lm.match_rules('Apache license version 2.0').first.first).to eq('Apache-2.0')

      expect(lm.match_rules('Apache License 2.0')[0][0]).to eq('Apache-2.0')
      expect(lm.match_rules('Apache License, Version 2.0')[0][0]).to eq('Apache-2.0')
      expect(lm.match_rules('Apache Software License')[0][0]).to eq('Apache-2.0')
      expect(lm.match_rules('License :: OSI Approved :: Apache Software License')[0][0]).to eq('Apache-2.0')
      expect(lm.match_rules('Apache License v2.0')[0][0]).to eq('Apache-2.0')
      expect(lm.match_rules('Apache License (2.0)')[0][0]).to eq('Apache-2.0')
      expect(lm.match_rules('Apache license')[0][0]).to eq('Apache-2.0')
      expect(lm.match_rules('Apache')[0][0]).to eq('Apache-2.0')
      expect(lm.match_rules('Apache Open Source License 2.0')[0][0]).to eq('Apache-2.0')
    end

    it "matches APL licenses" do
      expect(lm.match_rules('APLv1').first.first).to eq('APL-1.0')
      expect(lm.match_rules('APL-1').first.first).to eq('APL-1.0')
      expect(lm.match_rules('APL-v1').first.first).to eq('APL-1.0')
      expect(lm.match_rules('lic APLv1 lic').first.first).to eq('APL-1.0')
      expect(lm.match_rules('APL v1').first.first).to eq('APL-1.0')
      expect(lm.match_rules('APL 1.0').first.first).to eq('APL-1.0')
    end

    it "matches APLS-1.0 licenses" do
      expect(lm.match_rules('APSLv1.0').first.first).to eq('APSL-1.0')
      expect(lm.match_rules('APSL 1.0').first.first).to eq('APSL-1.0')
      expect(lm.match_rules('lic APSL-1.0 lic').first.first).to eq('APSL-1.0')
      expect(lm.match_rules('lic APSL-v1.0').first.first).to eq('APSL-1.0')

      expect(lm.match_rules('APSLv1')[0][0]).to eq('APSL-1.0')
      expect(lm.match_rules('APSL-v1')[0][0]).to eq('APSL-1.0')
      expect(lm.match_rules('APSL v1')[0][0]).to eq('APSL-1.0')

      expect(lm.match_rules('aa APPLE PUBLIC source')[0][0]).to eq('APSL-1.0')
    end

    it "matches APSL-1.1 licenses" do
      expect(lm.match_rules('APSLv1.1')[0][0]).to eq('APSL-1.1')
      expect(lm.match_rules('APSL 1.1')[0][0]).to eq('APSL-1.1')
      expect(lm.match_rules('APSL v1.1')[0][0]).to eq('APSL-1.1')
      expect(lm.match_rules('lic APSL v1.1 lic')[0][0]).to eq('APSL-1.1')
    end

    it "matches APSL-1.2 licenses" do
      expect(lm.match_rules('APSLv1.2')[0][0]).to eq('APSL-1.2')
      expect(lm.match_rules('APSL-1.2')[0][0]).to eq('APSL-1.2')
      expect(lm.match_rules('APSL v1.2')[0][0]).to eq('APSL-1.2')
      expect(lm.match_rules('APSL 1.2')[0][0]).to eq('APSL-1.2')
      expect(lm.match_rules('lic APSL 1.2 lic')[0][0]).to eq('APSL-1.2')
    end

    it "matches APSL-2.0 licenses" do
      expect(lm.match_rules('APSLv2.0')[0][0]).to eq('APSL-2.0')
      expect(lm.match_rules('APSL-2.0')[0][0]).to eq('APSL-2.0')
      expect(lm.match_rules('APSL v2.0')[0][0]).to eq('APSL-2.0')
      expect(lm.match_rules('APSL 2.0')[0][0]).to eq('APSL-2.0')
      expect(lm.match_rules('APSLv2')[0][0]).to eq('APSL-2.0')
      expect(lm.match_rules('APSL 2')[0][0]).to eq('APSL-2.0')
      expect(lm.match_rules('lic APSL 2.0 lic')[0][0]).to eq('APSL-2.0')
    end

    it "matches Artistic-1.0 licenses" do
      expect(lm.match_rules('ArtisticV1.0')[0][0]).to eq('Artistic-1.0')
      expect(lm.match_rules('Artistic V1.0')[0][0]).to eq('Artistic-1.0')
      expect(lm.match_rules('Artistic 1.0')[0][0]).to eq('Artistic-1.0')
    
      expect(lm.match_rules('ArtisticV1')[0][0]).to eq('Artistic-1.0')
      expect(lm.match_rules('Artistic V1')[0][0]).to eq('Artistic-1.0')
      expect(lm.match_rules('Artistic 1')[0][0]).to eq('Artistic-1.0')
      expect(lm.match_rules('uses ArtisticV1 license')[0][0]).to eq('Artistic-1.0')
    end

    it "matches Artistic-2.0 licenses" do
      expect(lm.match_rules('ArtisticV2.0')[0][0]).to eq('Artistic-2.0')
      expect(lm.match_rules('Artistic V2.0')[0][0]).to eq('Artistic-2.0')
      expect(lm.match_rules('Artistic 2.0')[0][0]).to eq('Artistic-2.0')
      expect(lm.match_rules('Artistic-2.0')[0][0]).to eq('Artistic-2.0')

      expect(lm.match_rules('ArtisticV2')[0][0]).to eq('Artistic-2.0')
      expect(lm.match_rules('Artistic 2')[0][0]).to eq('Artistic-2.0')
      expect(lm.match_rules('uses Artistic 2 license')[0][0]).to eq('Artistic-2.0')

      expect(lm.match_rules('uses Artistic License')[0][0]).to eq('Artistic-2.0')
    end

    it "matches Artistic-1.0-Perl licenses" do
      expect(lm.match_rules('Artistic-1.0-Perl')[0][0]).to eq('Artistic-1.0-Perl')
      expect(lm.match_rules('uses Artistic-1.0-Perl lic')[0][0]).to eq('Artistic-1.0-Perl')
      expect(lm.match_rules('Artistic 1.0-Perl')[0][0]).to eq('Artistic-1.0-Perl')
      expect(lm.match_rules('PerlArtistic')[0][0]).to eq('Artistic-1.0-Perl')
    end

    it "matches BeerWare" do
      expect(lm.match_rules('beerWare')[0][0]).to eq('Beerware')
      expect(lm.match_rules('Rel as Beer-Ware lic')[0][0]).to eq('Beerware')
      expect(lm.match_rules('BEER License')[0][0]).to eq('Beerware')
      expect(lm.match_rules('BEER')[0][0]).to eq('Beerware')
    end

    it "matches BitTorrent-1.1 rules" do
      expect(lm.match_rules('BitTorrent Open Source License')[0][0]).to eq('BitTorrent-1.1')
    end

    it "matches to BSD-2" do
      expect(lm.match_rules('BSD2')[0][0]).to eq('BSD-2-Clause')
      expect(lm.match_rules('BSD-2')[0][0]).to eq('BSD-2-Clause')
      expect(lm.match_rules('Uses BSD v2 lic')[0][0]).to eq('BSD-2-Clause')

      expect(lm.match_rules('FreeBSD')[0][0]).to eq('BSD-2-Clause')
    end

    it "matches to BSD-3" do
      expect(lm.match_rules('BSD3')[0][0]).to eq('BSD-3-Clause')
      expect(lm.match_rules('BSD v3')[0][0]).to eq('BSD-3-Clause')
      expect(lm.match_rules('BSD3')[0][0]).to eq('BSD-3-Clause')
      expect(lm.match_rules('BSD3 clause')[0][0]).to eq('BSD-3-Clause')
    end

    it "matches to BSD-4" do
      expect(lm.match_rules('BSDv4')[0][0]).to eq('BSD-4-Clause')
      expect(lm.match_rules('BSD v4')[0][0]).to eq('BSD-4-Clause')
      expect(lm.match_rules('BSD4 Clause')[0][0]).to eq('BSD-4-Clause')
      expect(lm.match_rules('BSD LISENCE')[0][0]).to eq('BSD-4-Clause')
      expect(lm.match_rules('uses BSD4 clause')[0][0]).to eq('BSD-4-Clause')

      expect(lm.match_rules('http://en.wikipedia.org/wiki/BSD_licenses')[0][0]).to eq('BSD-4-Clause')
    end

    it "matches to BSL-1.0" do
      expect(lm.match_rules('BSLv1.0')[0][0]).to eq('BSL-1.0')
      expect(lm.match_rules('BSL-v1')[0][0]).to eq('BSL-1.0')
      expect(lm.match_rules('uses BSL-1.0 lic')[0][0]).to eq('BSL-1.0')
      expect(lm.match_rules('Boost License 1.0')[0][0]).to eq('BSL-1.0')
    end

    it "matches to CC0-1.0" do
      expect(lm.match_rules('CC0-1.0')[0][0]).to eq('CC0-1.0')
      expect(lm.match_rules('CC0 1.0')[0][0]).to eq('CC0-1.0')
      expect(lm.match_rules('uses CC0-v1.0 lic')[0][0]).to eq('CC0-1.0')

      expect(lm.match_rules('CC0v1')[0][0]).to eq('CC0-1.0')
      expect(lm.match_rules('CC0-v1')[0][0]).to eq('CC0-1.0')
      expect(lm.match_rules('uses CC0 v1 license')[0][0]).to eq('CC0-1.0')
      expect(lm.match_rules('http://creativecommons.org/publicdomain/zero/1.0/')[0][0]).to eq('CC0-1.0')

    end

    it "matches to CC-BY-1.0" do
      expect(lm.match_rules('CC-BY-1.0')[0][0]).to eq('CC-BY-1.0')
      expect(lm.match_rules('CC BY 1.0')[0][0]).to eq('CC-BY-1.0')
      expect(lm.match_rules('uses CC BY-1.0 lic')[0][0]).to eq('CC-BY-1.0')

      expect(lm.match_rules('CC-BY-v1')[0][0]).to eq('CC-BY-1.0')
      expect(lm.match_rules('uses CC BY v1 lic')[0][0]).to eq('CC-BY-1.0')

    end

    it "matches to CC-BY-2.0" do
      expect(lm.match_rules('CC-by-2.0')[0][0]).to eq('CC-BY-2.0')
      expect(lm.match_rules('CC by v2.0')[0][0]).to eq('CC-BY-2.0')
      expect(lm.match_rules('uses CC-BY-2.0 lic')[0][0]).to eq('CC-BY-2.0')

      expect(lm.match_rules('CC-BY-2')[0][0]).to eq('CC-BY-2.0')
      expect(lm.match_rules('CC-by v2')[0][0]).to eq('CC-BY-2.0')
      expect(lm.match_rules('uses CC-BY-2 lic')[0][0]).to eq('CC-BY-2.0')
    end

    it "matches to CC-BY-2.5" do
      expect(lm.match_rules('CC-BY-2.5')[0][0]).to eq('CC-BY-2.5')
      expect(lm.match_rules('CC BY 2.5')[0][0]).to eq('CC-BY-2.5')
      expect(lm.match_rules('CC-BY v2.5')[0][0]).to eq('CC-BY-2.5')
      expect(lm.match_rules('uses CC-BY-2.5 lic')[0][0]).to eq('CC-BY-2.5')
    end

    it "matches to CC-BY-3.0" do
      expect(lm.match_rules('CC-BY-3.0')[0][0]).to eq('CC-BY-3.0')
      expect(lm.match_rules('CC BY 3.0')[0][0]).to eq('CC-BY-3.0')
      expect(lm.match_rules('CC-BY v3.0')[0][0]).to eq('CC-BY-3.0')
      expect(lm.match_rules('uses CC-BY-3.0')[0][0]).to eq('CC-BY-3.0')

      expect(lm.match_rules('CC-BY-3')[0][0]).to eq('CC-BY-3.0')
      expect(lm.match_rules('CC-BY v3')[0][0]).to eq('CC-BY-3.0')
      expect(lm.match_rules('(CC-BY) v3')[0][0]).to eq('CC-BY-3.0')
      expect(lm.match_rules('Creative Common "Attribution" license (CC-BY) v3')[0][0]).to eq('CC-BY-3.0')
      expect(lm.match_rules('Creative Commons BY 3.0')[0][0]).to eq('CC-BY-3.0')
      expect(lm.match_rules('Creative Commons License <http://creativecommons.org/licenses/by/3.0/')[0][0]).to eq('CC-BY-3.0')
      expect(lm.match_rules('See: https://creativecommons.org/licenses/by/3.0/')[0][0]).to eq('CC-BY-3.0')

    end

    it "matches to CC-BY-4.0" do
      expect(lm.match_rules('CC-BY-4.0')[0][0]).to eq('CC-BY-4.0')
      expect(lm.match_rules('CC BY 4.0')[0][0]).to eq('CC-BY-4.0')
      expect(lm.match_rules('uses CC-BY-4.0')[0][0]).to eq('CC-BY-4.0')

      expect(lm.match_rules('CC-BY-4')[0][0]).to eq('CC-BY-4.0')
      expect(lm.match_rules('CC-BY v4')[0][0]).to eq('CC-BY-4.0')

      expect(lm.match_rules('CREATIVE COMMONS ATTRIBUTION v4.0')[0][0]).to eq('CC-BY-4.0')
    end

    it "matches to CC-BY-SA-1.0" do
      expect(lm.match_rules('CC-BY-SA-1.0')[0][0]).to eq('CC-BY-SA-1.0')
      expect(lm.match_rules('CC BY-SA 1.0')[0][0]).to eq('CC-BY-SA-1.0')
      expect(lm.match_rules('uses CC BY-SA v1.0')[0][0]).to eq('CC-BY-SA-1.0')

      expect(lm.match_rules('CC-BY-SA v1')[0][0]).to eq('CC-BY-SA-1.0')
      expect(lm.match_rules('CC BY-SA-1')[0][0]).to eq('CC-BY-SA-1.0')
    end

    it "matches to CC-BY-SA-2.0" do
      expect(lm.match_rules('CC-BY-SA 2.0')[0][0]).to eq('CC-BY-SA-2.0')
      expect(lm.match_rules('CC BY-SA-2.0')[0][0]).to eq('CC-BY-SA-2.0')
      expect(lm.match_rules('CC BY-SA v2.0')[0][0]).to eq('CC-BY-SA-2.0')
      expect(lm.match_rules('uses CC BY-SA 2.0 lic')[0][0]).to eq('CC-BY-SA-2.0')

      expect(lm.match_rules('CC-BY-SA-2')[0][0]).to eq('CC-BY-SA-2.0')
      expect(lm.match_rules('CC BY-SA v2')[0][0]).to eq('CC-BY-SA-2.0')
    end

    it "matches to CC-BY-SA-2.5" do
      expect(lm.match_rules('CC-BY-SA-2.5')[0][0]).to eq('CC-BY-SA-2.5')
      expect(lm.match_rules('CC BY-SA 2.5')[0][0]).to eq('CC-BY-SA-2.5')
      expect(lm.match_rules('CC-BY-SA v2.5')[0][0]).to eq('CC-BY-SA-2.5')
      expect(lm.match_rules('uses CC BY-SA 2.5')[0][0]).to eq('CC-BY-SA-2.5')
    end

    it "matches to CC-BY-SA-3.0" do
      expect(lm.match_rules('CC BY-SA 3.0')[0][0]).to eq('CC-BY-SA-3.0')
      expect(lm.match_rules('CC-BY-SA-3.0')[0][0]).to eq('CC-BY-SA-3.0')
      expect(lm.match_rules('CC-BY-SA v3.0')[0][0]).to eq('CC-BY-SA-3.0')
      expect(lm.match_rules('uses CC BY-SA 3.0 lic')[0][0]).to eq('CC-BY-SA-3.0')

      expect(lm.match_rules('CC-BY-SA-3')[0][0]).to eq('CC-BY-SA-3.0')
      expect(lm.match_rules('CC BY-SA v3')[0][0]).to eq('CC-BY-SA-3.0')
      expect(lm.match_rules('uses CC BY-SA-3')[0][0]).to eq('CC-BY-SA-3.0')
      expect(lm.match_rules('http://creativecommons.org/licenses/by-sa/3.0/')[0][0]).to  eq('CC-BY-SA-3.0')

    end

    it "matches to CC-BY-SA-4.0" do
      expect(lm.match_rules('CC BY-SA 4.0')[0][0]).to eq('CC-BY-SA-4.0')
      expect(lm.match_rules('CC-BY-SA v4.0')[0][0]).to eq('CC-BY-SA-4.0')
      expect(lm.match_rules('uses CC BY SA 4.0 lic')[0][0]).to eq('CC-BY-SA-4.0')

      expect(lm.match_rules('CC-BY-SA v4')[0][0]).to eq('CC-BY-SA-4.0')
      expect(lm.match_rules('CC BY-SA 4')[0][0]).to eq('CC-BY-SA-4.0')
      expect(lm.match_rules('uses CC BY-SA v4 lic')[0][0]).to eq('CC-BY-SA-4.0')

      expect(lm.match_rules('CCSA-4.0')[0][0]).to eq('CC-BY-SA-4.0')
      expect(lm.match_rules('uses CCSA-4.0 lic')[0][0]).to eq('CC-BY-SA-4.0')
    end

    it "matches to CC-BY-NC-1.0" do
      expect(lm.match_rules('CC BY-NC 1.0')[0][0]).to eq('CC-BY-NC-1.0')
      expect(lm.match_rules('CC BY NC v1.0')[0][0]).to eq('CC-BY-NC-1.0')
      expect(lm.match_rules('uses CC-BY-NC v1.0 lic')[0][0]).to eq('CC-BY-NC-1.0')

      expect(lm.match_rules('CC-BY-NC-1')[0][0]).to eq('CC-BY-NC-1.0')
      expect(lm.match_rules('CC BY-NC v1')[0][0]).to eq('CC-BY-NC-1.0')
      expect(lm.match_rules('uses CC-BY-NC-1 lic')[0][0]).to eq('CC-BY-NC-1.0')
    end

    it "matches to CC-BY-NC-2.0" do
      expect(lm.match_rules('CC-BY-NC 2.0')[0][0]).to eq('CC-BY-NC-2.0')
      expect(lm.match_rules('CC-BY-NCv2.0')[0][0]).to eq('CC-BY-NC-2.0')
      expect(lm.match_rules('uses CC-BY-NC 2.0 lic')[0][0]).to eq('CC-BY-NC-2.0')
    end

    it "matches to CC-BY-NC-2.5" do
      expect(lm.match_rules('CC-BY-NC 2.5')[0][0]).to eq('CC-BY-NC-2.5')
      expect(lm.match_rules('CC BY-NC v2.5')[0][0]).to eq('CC-BY-NC-2.5')
      expect(lm.match_rules('CC-BY-NC-2.5')[0][0]).to eq('CC-BY-NC-2.5')
      expect(lm.match_rules('uses CC-BY-NC 2.5 lic')[0][0]).to eq('CC-BY-NC-2.5')
    end

    it "matches to CC-BY-NC-3.0" do
      expect(lm.match_rules('CC-BY-NC 3.0')[0][0]).to eq('CC-BY-NC-3.0')
      expect(lm.match_rules('CC BY-NC v3.0')[0][0]).to eq('CC-BY-NC-3.0')
      expect(lm.match_rules('uses CC BY-NC3.0 lic')[0][0]).to eq('CC-BY-NC-3.0')
      
      expect(lm.match_rules('CC BY NC v3')[0][0]).to eq('CC-BY-NC-3.0')
      expect(lm.match_rules('CC-BY-NC-3')[0][0]).to eq('CC-BY-NC-3.0')
      expect(lm.match_rules('uses CC-BY-NC v3 lic')[0][0]).to eq('CC-BY-NC-3.0')
    end

    it "matches to CC-BY-NC-4.0" do
      expect(lm.match_rules('CC-BY-NC 4.0')[0][0]).to eq('CC-BY-NC-4.0')
      expect(lm.match_rules('CC BY-NC v4.0')[0][0]).to eq('CC-BY-NC-4.0')
      expect(lm.match_rules('uses CC-BY-NC 4.0 lic')[0][0]).to eq('CC-BY-NC-4.0')

      expect(lm.match_rules('CC-BY-NC v4')[0][0]).to eq('CC-BY-NC-4.0')
      expect(lm.match_rules('CC BY-NC-4')[0][0]).to eq('CC-BY-NC-4.0')
      expect(lm.match_rules('uses CC-BY-NC 4 lic')[0][0]).to eq('CC-BY-NC-4.0')
      expect(lm.match_rules('http://creativecommons.org/licenses/by-nc/3.0/')[0][0]).to eq('CC-BY-NC-4.0')
    end

    it "matches to CC-BY-NC-SA-1.0" do
      expect(lm.match_rules('CC-BY-NC-SA-1.0')[0][0]).to eq('CC-BY-NC-SA-1.0')
      expect(lm.match_rules('CC BY-NC SA v1.0')[0][0]).to eq('CC-BY-NC-SA-1.0')
      expect(lm.match_rules('uses CC BY-NC-SA 1.0 lic')[0][0]).to eq('CC-BY-NC-SA-1.0')

      expect(lm.match_rules('CC BY-NC-SA v1')[0][0]).to eq('CC-BY-NC-SA-1.0')
      expect(lm.match_rules('CC BY-NC-SA-1')[0][0]).to eq('CC-BY-NC-SA-1.0')
      expect(lm.match_rules('uses CC-BY-NC-SA-1 lic')[0][0]).to eq('CC-BY-NC-SA-1.0')
    end

    it "matches to CC-BY-NC-SA-2.0" do
      expect(lm.match_rules('CC BY-NC-SA 2.0')[0][0]).to eq('CC-BY-NC-SA-2.0')
      expect(lm.match_rules('CC-BY-NC-SA-v2.0')[0][0]).to eq('CC-BY-NC-SA-2.0')
      expect(lm.match_rules('uses CC-BY-NC-SA 2.0 lic')[0][0]).to eq('CC-BY-NC-SA-2.0')
    end

    it "matches to CC-BY-NC-SA-2.5" do
      expect(lm.match_rules('CC-BY-NC-SA-2.5')[0][0]).to eq('CC-BY-NC-SA-2.5')
      expect(lm.match_rules('CC BY-NC-SA v2.5')[0][0]).to eq('CC-BY-NC-SA-2.5')
      expect(lm.match_rules('uses CC BY-NC SA2.5')[0][0]).to eq('CC-BY-NC-SA-2.5')
    end

    it "matches to CC-BY-NC-SA-3.0" do
      expect(lm.match_rules('CC-BY-NC-SA-3.0')[0][0]).to eq('CC-BY-NC-SA-3.0')
      expect(lm.match_rules('CC BY-NC-SA v3.0')[0][0]).to eq('CC-BY-NC-SA-3.0')
      expect(lm.match_rules('uses CC BY NC-SA-3.0')[0][0]).to eq('CC-BY-NC-SA-3.0')


      expect(lm.match_rules('CC BY-NC-SA v3')[0][0]).to eq('CC-BY-NC-SA-3.0')
      expect(lm.match_rules('uses CC-BY-NC-SA-3 lic')[0][0]).to eq('CC-BY-NC-SA-3.0')

      expect(lm.match_rules('BY-NC-SA v3.0')[0][0]).to eq('CC-BY-NC-SA-3.0')
      expect(lm.match_rules('as By-NC-SA 3.0 lic')[0][0]).to eq('CC-BY-NC-SA-3.0')
      expect(lm.match_rules('http://creativecommons.org/licenses/by-nc-sa/3.0/us/')[0][0]).to eq('CC-BY-NC-SA-3.0')

    end

    it "matches to CC-BY-NC-SA-4.0" do
      expect(lm.match_rules('CC-BY-NC-SA-4.0')[0][0]).to eq('CC-BY-NC-SA-4.0')
      expect(lm.match_rules('CC BY-NC SAv4.0')[0][0]).to eq('CC-BY-NC-SA-4.0')
      expect(lm.match_rules('uses CC-BY-NC-SA v4.0')[0][0]).to eq('CC-BY-NC-SA-4.0')

      expect(lm.match_rules('CC-BY-NC-SA v4')[0][0]).to eq('CC-BY-NC-SA-4.0')
      expect(lm.match_rules('CC BY-NC-SA-4')[0][0]).to eq('CC-BY-NC-SA-4.0')
      expect(lm.match_rules('uses CC-BY-NC-SA-v4 lic')[0][0]).to eq('CC-BY-NC-SA-4.0')
    end

    it "matches to CC-BY-ND-1.0" do
      expect(lm.match_rules('CC-BY-ND-1.0')[0][0]).to eq('CC-BY-ND-1.0')
      expect(lm.match_rules('CC-BY-ND v1.0')[0][0]).to eq('CC-BY-ND-1.0')
      expect(lm.match_rules('uses CC BY-ND 1.0 lic')[0][0]).to eq('CC-BY-ND-1.0')
    end

    it "matches to CC-BY-ND-2.0" do
      expect(lm.match_rules('CC-BY-ND-2.0')[0][0]).to eq('CC-BY-ND-2.0')
      expect(lm.match_rules('CC-BY-ND v2.0')[0][0]).to eq('CC-BY-ND-2.0')
      expect(lm.match_rules('uses CC BY-ND 2.0 lic')[0][0]).to eq('CC-BY-ND-2.0')
    end

    it "matches to CC-BY-ND-2.5" do
      expect(lm.match_rules('CC-BY-ND-2.5')[0][0]).to eq('CC-BY-ND-2.5')
      expect(lm.match_rules('CC-BY-ND v2.5')[0][0]).to eq('CC-BY-ND-2.5')
      expect(lm.match_rules('uses CC BY-ND 2.5 lic')[0][0]).to eq('CC-BY-ND-2.5')
    end

    it "matches to CC-BY-ND-3.0" do
      expect(lm.match_rules('CC-BY-ND-3.0')[0][0]).to eq('CC-BY-ND-3.0')
      expect(lm.match_rules('CC-BY-ND v3.0')[0][0]).to eq('CC-BY-ND-3.0')
      expect(lm.match_rules('uses CC BY-ND 3.0 lic')[0][0]).to eq('CC-BY-ND-3.0')
    end

    it "matches to CC-BY-ND-4.0" do
      expect(lm.match_rules('CC-BY-ND-4.0')[0][0]).to eq('CC-BY-ND-4.0')
      expect(lm.match_rules('CC-BY-ND v4.0')[0][0]).to eq('CC-BY-ND-4.0')
      expect(lm.match_rules('uses CC BY-ND 4.0 lic')[0][0]).to eq('CC-BY-ND-4.0')
      expect(lm.match_rules('CC BY-NC-ND 4.0')[0][0]).to eq('CC-BY-ND-4.0')
    end

    it "matches CDDL-1.0 rules" do
      expect(lm.match_rules('CDDL-V1.0')[0][0]).to eq('CDDL-1.0')
      expect(lm.match_rules('CDDL 1.0')[0][0]).to eq('CDDL-1.0')
      expect(lm.match_rules('uses CDDLv1.0')[0][0]).to eq('CDDL-1.0')

      expect(lm.match_rules('CDDL v1')[0][0]).to eq('CDDL-1.0')
      expect(lm.match_rules('CDDL-1')[0][0]).to eq('CDDL-1.0')
      expect(lm.match_rules('uses CDDL v1 lic')[0][0]).to eq('CDDL-1.0')

      expect(lm.match_rules('CDDL License')[0][0]).to eq('CDDL-1.0')
      expect(lm.match_rules('COMMON DEVELOPMENT AND DISTRIBUTION LICENSE')[0][0]).to eq('CDDL-1.0')
    end

    it "matches CECILL-B rules" do
      expect(lm.match_rules('CECILL-B')[0][0]).to eq('CECILL-B')
      expect(lm.match_rules('CECILL B')[0][0]).to eq('CECILL-B')
      expect(lm.match_rules('uses CECILL_B lic')[0][0]).to eq('CECILL-B')
      expect(lm.match_rules('CECILLB')[0][0]).to eq('CECILL-B')
    end

    it "matches CECILL-C rules" do
      expect(lm.match_rules('CECILL-C')[0][0]).to eq('CECILL-C')
      expect(lm.match_rules('CECILL C')[0][0]).to eq('CECILL-C')
      expect(lm.match_rules('uses CECILL-C lic')[0][0]).to eq('CECILL-C')
      expect(lm.match_rules('CECILLC')[0][0]).to eq('CECILL-C')
    end

    it "matches CECILL-1.0 rules" do
      expect(lm.match_rules('CECILL-1.0')[0][0]).to eq('CECILL-1.0')
      expect(lm.match_rules('CECILL v1.0')[0][0]).to eq('CECILL-1.0')
      expect(lm.match_rules('uses CECILL 1.0 lic')[0][0]).to eq('CECILL-1.0')

      expect(lm.match_rules('CECILL-1')[0][0]).to eq('CECILL-1.0')
      expect(lm.match_rules('CECILL v1')[0][0]).to eq('CECILL-1.0')
      expect(lm.match_rules('uses CECILL v1 lic')[0][0]).to eq('CECILL-1.0')

      expect(lm.match_rules('http://www.cecill.info')[0][0]).to eq('CECILL-1.0')
    end

    it "matches CECILL-2.1 rules" do
      expect(lm.match_rules('CECILL-2.1')[0][0]).to eq('CECILL-2.1')
      expect(lm.match_rules('CECILL v2.1')[0][0]).to eq('CECILL-2.1')
      expect(lm.match_rules('uses CECILL 2.1 lic')[0][0]).to eq('CECILL-2.1')

      expect(lm.match_rules('Cecill Version 2.1')[0][0]).to eq('CECILL-2.1')
    end
    
    it "matches CPAL-1.0 rules" do
      expect(lm.match_rules('Common Public Attribution License 1.0')[0][0]).to eq('CPAL-1.0')
      expect(lm.match_rules('CPAL-1.0')[0][0]).to eq('CPAL-1.0')
      expect(lm.match_rules('CPAL')[0][0]).to eq('CPAL-1.0')
    end

    it "matches CPL-1.0 rules" do
      expect(lm.match_rules('CPL-1.0')[0][0]).to eq('CPL-1.0')
      expect(lm.match_rules('CPL v1.0')[0][0]).to eq('CPL-1.0')
      expect(lm.match_rules('uses CPL 1.0 lic')[0][0]).to eq('CPL-1.0')

      expect(lm.match_rules('CPL-v1')[0][0]).to eq('CPL-1.0')
      expect(lm.match_rules('CPL v1')[0][0]).to eq('CPL-1.0')
      expect(lm.match_rules('uses CPL-1 lic')[0][0]).to eq('CPL-1.0')

      expect(lm.match_rules('uses COMMON PUBLIC LICENSE')[0][0]).to eq('CPL-1.0')
    end

    it "matches D-FSL-1.0" do
      expect(lm.match_rules('DFSL-v1.0')[0][0]).to eq('D-FSL-1.0')
      expect(lm.match_rules('D-FSL 1.0')[0][0]).to eq('D-FSL-1.0')
      expect(lm.match_rules('uses D-FSL v1.0 lic')[0][0]).to eq('D-FSL-1.0')

      expect(lm.match_rules('D-FSL v1')[0][0]).to eq('D-FSL-1.0')
      expect(lm.match_rules('DFSL-1')[0][0]).to eq('D-FSL-1.0')
      expect(lm.match_rules('uses DFSL v1 lic')[0][0]).to eq('D-FSL-1.0')

      expect(lm.match_rules('German Free Software')[0][0]).to eq('D-FSL-1.0')
      expect(lm.match_rules('Deutsche Freie Software Lizenz')[0][0]).to eq('D-FSL-1.0')
    end

    it "matches ECL-1.0" do
      expect(lm.match_rules('ECL v1.0')[0][0]).to eq('ECL-1.0')
      expect(lm.match_rules('ECL-1.0')[0][0]).to eq('ECL-1.0')
      expect(lm.match_rules('uses ECL 1.0 lic')[0][0]).to eq('ECL-1.0')

      expect(lm.match_rules('ECL v1')[0][0]).to eq('ECL-1.0')
      expect(lm.match_rules('ECL-1')[0][0]).to eq('ECL-1.0')
      expect(lm.match_rules('uses ECL-V1 lic')[0][0]).to eq('ECL-1.0')
    end

    it "matches ECL-2.0" do
      expect(lm.match_rules('ECL-2.0')[0][0]).to eq('ECL-2.0')
      expect(lm.match_rules('ECL v2.0')[0][0]).to eq('ECL-2.0')
      expect(lm.match_rules('uses ECL-2.0 lic')[0][0]).to eq('ECL-2.0')

      expect(lm.match_rules('ECL-v2')[0][0]).to eq('ECL-2.0')
      expect(lm.match_rules('ECL 2')[0][0]).to eq('ECL-2.0')
      expect(lm.match_rules('uses ECL 2 lic')[0][0]).to eq('ECL-2.0')

      expect(lm.match_rules('EDUCATIONAL COMMUNITY LICENSE VERSION 2.0'))
    end

    it "matches EFL-1.0" do
      expect(lm.match_rules('EFL-1.0')[0][0]).to eq('EFL-1.0')
      expect(lm.match_rules('EFL v1.0')[0][0]).to eq('EFL-1.0')
      expect(lm.match_rules('uses EFL 1.0 lic')[0][0]).to eq('EFL-1.0')

      expect(lm.match_rules('EFL v1')[0][0]).to eq('EFL-1.0')
      expect(lm.match_rules('EFL-1')[0][0]).to eq('EFL-1.0')
      expect(lm.match_rules('uses EFL v1 lic')[0][0]).to eq('EFL-1.0')
    end

    it "matches EFL-2.0" do
      expect(lm.match_rules('EFL-2.0')[0][0]).to eq('EFL-2.0')
      expect(lm.match_rules('EFL v2.0')[0][0]).to eq('EFL-2.0')
      expect(lm.match_rules('uses EFL 2.0 lic')[0][0]).to eq('EFL-2.0')

      expect(lm.match_rules('EFL v2')[0][0]).to eq('EFL-2.0')
      expect(lm.match_rules('EFL-2')[0][0]).to eq('EFL-2.0')
      expect(lm.match_rules('uses EFL v2 lic')[0][0]).to eq('EFL-2.0')

      expect(lm.match_rules('Eiffel Forum License version 2')[0][0]).to eq('EFL-2.0')
      expect(lm.match_rules('Eiffel Forum License 2')[0][0]).to eq('EFL-2.0')
    end

    it "matches ESA-1.0" do
      expect(lm.match_rules('ESCL - Type 1')[0][0]).to eq('ESA-1.0')
      expect(lm.match_rules('ESA Software Community License – Type 1')[0][0]).to eq('ESA-1.0')
    end

    it "matches EPL-1.0" do
      expect(lm.match_rules('EPL-1.0')[0][0]).to eq('EPL-1.0')
      expect(lm.match_rules('EPL v1.0')[0][0]).to eq('EPL-1.0')
      expect(lm.match_rules('uses EPLv1.0 lic')[0][0]).to eq('EPL-1.0')

      expect(lm.match_rules('EPLv1')[0][0]).to eq('EPL-1.0')
      expect(lm.match_rules('EPL-1')[0][0]).to eq('EPL-1.0')
      expect(lm.match_rules('uses EPL v1 lic')[0][0]).to eq('EPL-1.0')

      expect(lm.match_rules('ECLIPSE PUBLIC LICENSE 1.0')[0][0]).to eq('EPL-1.0')
      expect(lm.match_rules('ECLIPSE PUBLIC LICENSE')[0][0]).to eq('EPL-1.0')
    end

    it "matches EUPL-1.0 " do
      expect(lm.match_rules('EUPL-1.0')[0][0]).to eq('EUPL-1.0')
      expect(lm.match_rules('EUPL v1.0')[0][0]).to eq('EUPL-1.0')
      expect(lm.match_rules('(EUPL1.0)')[0][0]).to eq('EUPL-1.0')
      expect(lm.match_rules('uses EUPL 1.0 lic')[0][0]).to eq('EUPL-1.0')
    end

    it "matches EUPL-1.1 " do
      expect(lm.match_rules('EUPL-1.1')[0][0]).to eq('EUPL-1.1')
      expect(lm.match_rules('EUPL v1.1')[0][0]).to eq('EUPL-1.1')
      expect(lm.match_rules('(EUPL1.1)')[0][0]).to eq('EUPL-1.1')
      expect(lm.match_rules('uses EUPL 1.1 lic')[0][0]).to eq('EUPL-1.1')

      expect(lm.match_rules('EUROPEAN UNION PUBLIC LICENSE 1.1')[0][0]).to eq('EUPL-1.1')
      expect(lm.match_rules('European Union Public License')[0][0]).to eq('EUPL-1.1')
      expect(lm.match_rules('EUPL ')[0][0]).to eq('EUPL-1.1')
    end

    it "matches GFDL-1.0 rules" do
      expect(lm.match_rules('GNU Free Documentation License (FDL)')[0][0]).to eq('GFDL-1.0')
      expect(lm.match_rules('FDL')[0][0]).to eq('GFDL-1.0')
    end

    it "matches GPL-1.0 rules" do
      expect(lm.match_rules('GPL-1.0')[0][0]).to eq('GPL-1.0')
      expect(lm.match_rules('GPL v1.0')[0][0]).to eq('GPL-1.0')
      expect(lm.match_rules('uses GPL 1.0 lic')[0][0]).to eq('GPL-1.0')

      expect(lm.match_rules('GPLv1')[0][0]).to eq('GPL-1.0')
      expect(lm.match_rules('GPL-1')[0][0]).to eq('GPL-1.0')
      expect(lm.match_rules('uses GPL v1 lic')[0][0]).to eq('GPL-1.0')

      expect(lm.match_rules('GNU Public License 1.0')[0][0]).to eq('GPL-1.0')
    end

    it "matches GPL-2.0 rules" do
      expect(lm.match_rules('GPL v2.0')[0][0]).to eq('GPL-2.0') 
      expect(lm.match_rules('GPL-2.0')[0][0]).to eq('GPL-2.0')
      expect(lm.match_rules('uses GPL 2.0 lic')[0][0]).to eq('GPL-2.0')

      expect(lm.match_rules('GPL-2')[0][0]).to eq('GPL-2.0')
      expect(lm.match_rules('GPL v2')[0][0]).to eq('GPL-2.0')
      expect( lm.match_rules('GNU GPL v2 or later, plus transitive 12 m').first.first ).to eq('GPL-2.0')

      expect(lm.match_rules('GNU PUBLIC LICENSE 2.0')[0][0]).to eq('GPL-2.0')
      expect(lm.match_rules('GNU PUBLIC LICENSE 2')[0][0]).to eq('GPL-2.0')
      expect(lm.match_rules('GNU General Public License v2.0')[0][0]).to eq('GPL-2.0')
      expect(lm.match_rules('GNU Public License >=2 (ask me if you want other)')[0][0]).to eq('GPL-2.0')
      expect(lm.match_rules('GNU GPL v2')[0][0]).to eq('GPL-2.0')
      expect(lm.match_rules('GLPv2')[0][0]).to eq('GPL-2.0')
    end

    it "matches GPL-3.0 rules" do
      expect(lm.match_rules('GPL-3.0')[0][0]).to eq('GPL-3.0')
      expect(lm.match_rules('GPL v3.0')[0][0]).to eq('GPL-3.0')
      expect(lm.match_rules('uses GPL 3.0 lic')[0][0]).to eq('GPL-3.0')

      expect(lm.match_rules('GPL v3')[0][0]).to eq('GPL-3.0')
      expect(lm.match_rules('GPL-3')[0][0]).to eq('GPL-3.0')
      expect(lm.match_rules('uses GPL v3 lic')[0][0]).to eq('GPL-3.0')

      expect(lm.match_rules('GNU Public License v3.0')[0][0]).to eq('GPL-3.0')
      expect(lm.match_rules('GNU PUBLIC license 3')[0][0]).to eq('GPL-3.0')
      expect(lm.match_rules('GNU PUBLIC v3')[0][0]).to eq('GPL-3.0')

      expect(lm.match_rules('GNUGPL-v3')[0][0]).to eq('GPL-3.0')
      expect(lm.match_rules('GNU General Public License version 3')[0][0]).to eq('GPL-3.0')
      expect(lm.match_rules('GPLv.3')[0][0]).to eq('GPL-3.0')

    end

    it "matches IDPL-1.0 rules" do
      expect(lm.match_rules('IDPL 1.0')[0][0]).to eq('IDPL-1.0')
      expect(lm.match_rules('http://www.firebirdsql.org/index.php?op=doc&id=idpl')[0][0]).to eq('IDPL-1.0')
    end

    it "matches IPL-1.0 rules" do
      expect(lm.match_rules('IBM Open Source License')[0][0]).to eq('IPL-1.0')
      expect(lm.match_rules('IBM Public License')[0][0]).to eq('IPL-1.0')
    end

    it "matches ISC rules" do
      expect(lm.match_rules('ISC license')[0][0]).to eq('ISC')
      expect(lm.match_rules('uses ISC license')[0][0]).to eq('ISC')
      
      expect(lm.match_rules('(ISCL)')[0][0]).to eq('ISC')
    end

    it "matches JSON license rules" do
      expect(lm.match_rules('JSON license')[0][0]).to eq('JSON')
    end

    it "matches LGPL-2.0 rules" do
      expect(lm.match_rules('LGPL-2.0')[0][0]).to eq('LGPL-2.0')
      expect(lm.match_rules('uses LGPL v2.0')[0][0]).to eq('LGPL-2.0')

      expect(lm.match_rules('LGPL v2')[0][0]).to eq('LGPL-2.0')
      expect(lm.match_rules('LGPL2')[0][0]).to eq('LGPL-2.0')
      expect(lm.match_rules('uses LGPL-2 lic')[0][0]).to eq('LGPL-2.0')

      expect(lm.match_rules('GNU Lesser General Public License v2')[0][0]).to eq('LGPL-2.0')
      expect(lm.match_rules('GNU Lesser General Public License v2 or higher')[0][0]).to eq('LGPL-2.0')
    end

    it "matches LGPL-2.1 rules" do
      expect(lm.match_rules('LGPL-2.1')[0][0]).to eq('LGPL-2.1')
      expect(lm.match_rules('LGPL v2.1')[0][0]).to eq('LGPL-2.1')
      expect(lm.match_rules('uses LGPL 2.1 lic')[0][0]).to eq('LGPL-2.1')

      expect(lm.match_rules('GNU LESSER GENERAL PUBLIC LICENSE Version 2.1, February')[0][0]).to eq('LGPL-2.1')
      expect(lm.match_rules('GNU Lesser General Public License, version 2.1')[0][0]).to eq('LGPL-2.1')
      expect(lm.match_rules('GNU Lesser General Public License v2.1 (see COPYING)')[0][0]).to eq('LGPL-2.1')

    end

    it "matches LGPL-3.0 rules" do
      expect(lm.match_rules('LGPL-3.0')[0][0]).to eq('LGPL-3.0')
      expect(lm.match_rules('LGPL v3.0')[0][0]).to eq('LGPL-3.0')
      expect(lm.match_rules('uses LGPL 3.0 lic')[0][0]).to eq('LGPL-3.0')

      expect(lm.match_rules('LGPL v3')[0][0]).to eq('LGPL-3.0')
      expect(lm.match_rules('LGPL3')[0][0]).to eq('LGPL-3.0')
      expect(lm.match_rules('LGPLv3+')[0][0]).to eq('LGPL-3.0')
      expect(lm.match_rules('uses LGPL 3 lic')[0][0]).to eq('LGPL-3.0')

      expect(lm.match_rules('LESSER GENERAL PUBLIC License v3')[0][0]).to eq('LGPL-3.0')
      expect(lm.match_rules(
        'GNU Lesser General Public License v. 3.0'
      )[0][0]).to eq('LGPL-3.0')
      expect(lm.match_rules('http://www.gnu.org/copyleft/lesser.html')[0][0]).to eq('LGPL-3.0')
      expect(lm.match_rules('GNU LESSER GENERAL PUBLIC LICENSE Version 3')[0][0]).to eq('LGPL-3.0')
      expect(lm.match_rules('LPGLv3+')[0][0]).to eq('LGPL-3.0')

      expect(lm.match_rules('GNU Lesser General Public License, version 3.0')[0][0]).to eq('LGPL-3.0')
    end

    it "matches MirOS rules" do
      expect(lm.match_rules('MirOs')[0][0]).to eq('MirOS')
      expect(lm.match_rules('uses MirOS lic')[0][0]).to eq('MirOS')
    end

    it "matches noisy MIT license names" do
      expect(lm.match_rules('MIT License')[0][0]).to eq('MIT')
      expect(lm.match_rules('MIT')[0][0]).to eq('MIT')
      expect( lm.match_rules('Original Cutadapt code is under MIT license;')[0][0]).to eq('MIT')
      expect(lm.match_rules('MIT_License.txt')[0][0]).to eq('MIT')
      expect(lm.match_rules('MTI')[0][0]).to eq('MIT')
    end

    it "matches MPL-1.0 rules" do
      expect(lm.match_rules('MPL-V1.0')[0][0]).to eq('MPL-1.0')
      expect(lm.match_rules('MPL 1.0')[0][0]).to eq('MPL-1.0')
      expect(lm.match_rules('uses MPL 1.0 lic')[0][0]).to eq('MPL-1.0')

      expect(lm.match_rules('MPL v1')[0][0]).to eq('MPL-1.0')
      expect(lm.match_rules('MPL-1')[0][0]).to eq('MPL-1.0')
      expect(lm.match_rules('uses MPL v1 lic')[0][0]).to eq('MPL-1.0')

      expect(lm.match_rules('Mozilla Public License 1.0 (MPL)')[0][0]).to eq('MPL-1.0')
    end

    it "matches MPL-1.1 rules" do
      expect(lm.match_rules('MPL-1.1')[0][0]).to eq('MPL-1.1')
      expect(lm.match_rules('MPL v1.1')[0][0]).to eq('MPL-1.1')
      expect(lm.match_rules('uses MPL 1.1 lic')[0][0]).to eq('MPL-1.1')
    end

    it "matches MPL-2.0 rules" do
      expect(lm.match_rules('MPL-2.0')[0][0]).to eq('MPL-2.0')
      expect(lm.match_rules('MPL v2.0')[0][0]).to eq('MPL-2.0')
      expect(lm.match_rules('uses MPL 2.0 lic')[0][0]).to eq('MPL-2.0')


      expect(lm.match_rules('MPL v2')[0][0]).to eq('MPL-2.0')
      expect(lm.match_rules('MPL-2')[0][0]).to eq('MPL-2.0')
      expect(lm.match_rules('uses MPL 2 lic')[0][0]).to eq('MPL-2.0')

      expect(lm.match_rules('Mozilla Public License 2.0')[0][0]).to eq('MPL-2.0')
      expect(lm.match_rules('Mozilla Public License, v. 2.0')[0][0]).to eq('MPL-2.0')
      expect(lm.match_rules('Mozilla Public License')[0][0]).to eq('MPL-2.0')
    end

    it "matches MS-PL rules" do
      expect(lm.match_rules('MS-PL')[0][0]).to eq('MS-PL')
      expect(lm.match_rules('MSPL')[0][0]).to eq('MS-PL')
      expect(lm.match_rules('uses MS-PL')[0][0]).to eq('MS-PL')
    end

    it "matches MS-RL rules" do
      expect(lm.match_rules('MS-RL')[0][0]).to eq('MS-RL')
      expect(lm.match_rules('MSRL')[0][0]).to eq('MS-RL')
      expect(lm.match_rules('uses MS-RL')[0][0]).to eq('MS-RL')
    end

    it "matches NASA-1.3 rules" do
      expect(lm.match_rules('NASAv1.3')[0][0]).to eq('NASA-1.3')
      expect(lm.match_rules('uses NASA 1.3 lic')[0][0]).to eq('NASA-1.3')

      expect(lm.match_rules('NASA Open Source Agreement version 1.3')[0][0]).to eq('NASA-1.3')
    end

    it "matches NCSA rules" do
      expect(lm.match_rules('NCSA license')[0][0]).to eq('NCSA')
      expect(lm.match_rules('use NCSA license')[0][0]).to eq('NCSA')

      expect(lm.match_rules('NCSA')[0][0]).to eq('NCSA')
      expect(lm.match_rules('Illinois NCSA Open Source')[0][0]).to eq('NCSA')
    end

    it "matches NGPL rules" do
      expect(lm.match_rules('NGPL license')[0][0]).to eq('NGPL')
      expect(lm.match_rules('NGPL')[0][0]).to eq('NGPL')
    end

    it "matches NOKIA rules" do
      expect(lm.match_rules('Nokia Open Source License (NOKOS)')[0][0]).to eq('NOKIA')
    end
    
    it "matches NPL-1.1 rules" do
      expect(lm.match_rules('(NPL)')[0][0]).to eq('NPL-1.1')
      expect(lm.match_rules('Netscape Public License (NPL)')[0][0]).to eq('NPL-1.1')
    end

    it "matches NPOSL-3.0" do
      expect(lm.match_rules('NPOSL-3.0')[0][0]).to eq('NPOSL-3.0')
      expect(lm.match_rules('NPOSL v3.0')[0][0]).to eq('NPOSL-3.0')
      expect(lm.match_rules('uses NPOSL 3.0 lic')[0][0]).to eq('NPOSL-3.0')

      expect(lm.match_rules('NPOSL v3')[0][0]).to eq('NPOSL-3.0')
      expect(lm.match_rules('NPOSL-3')[0][0]).to eq('NPOSL-3.0')
      expect(lm.match_rules('uses NPOSL 3 lic')[0][0]).to eq('NPOSL-3.0')
    end

    it "matches OFL-1.0" do
      expect(lm.match_rules('OFL-1.0')[0][0]).to eq('OFL-1.0')
      expect(lm.match_rules('OFL v1.0')[0][0]).to eq('OFL-1.0')
      expect(lm.match_rules('uses OFL 1.0 lic')[0][0]).to eq('OFL-1.0')

      expect(lm.match_rules('OFL v1')[0][0]).to eq('OFL-1.0')
      expect(lm.match_rules('OFL-1')[0][0]).to eq('OFL-1.0')
      expect(lm.match_rules('uses OFL 1 lic')[0][0]).to eq('OFL-1.0')
  
      expect(lm.match_rules('SIL OFL 1.0')[0][0]).to eq('OFL-1.0')
    end

    it "matches OFL-1.1" do
      expect(lm.match_rules('OFL-1.1')[0][0]).to eq('OFL-1.1')
      expect(lm.match_rules('OFL v1.1')[0][0]).to eq('OFL-1.1')
      expect(lm.match_rules('uses OFL 1.1 lic')[0][0]).to eq('OFL-1.1')

      expect(lm.match_rules('SIL OFL 1.1')[0][0]).to eq('OFL-1.1')
      expect(lm.match_rules('uses SIL OFL 1.1 lic')[0][0]).to eq('OFL-1.1')
    end

    it "matches OSL-1.0" do
      expect(lm.match_rules('OSL-1.0')[0][0]).to eq('OSL-1.0')
      expect(lm.match_rules('OSL v1.0')[0][0]).to eq('OSL-1.0')
      expect(lm.match_rules('uses OSL 1.0 lic')[0][0]).to eq('OSL-1.0')

      expect(lm.match_rules('OSL v1')[0][0]).to eq('OSL-1.0')
      expect(lm.match_rules('OSL-1')[0][0]).to eq('OSL-1.0')
      expect(lm.match_rules('uses OSL 1 lic')[0][0]).to eq('OSL-1.0')
    end

    it "matches OSL-2.0" do
      expect(lm.match_rules('OSL-2.0')[0][0]).to eq('OSL-2.0')
      expect(lm.match_rules('OSL v2.0')[0][0]).to eq('OSL-2.0')
      expect(lm.match_rules('uses OSL 2.0 lic')[0][0]).to eq('OSL-2.0')

      expect(lm.match_rules('OSL v2')[0][0]).to eq('OSL-2.0')
      expect(lm.match_rules('uses OSL 2 lic')[0][0]).to eq('OSL-2.0')
    end

    it "matches OSL-2.1 rules" do
      expect(lm.match_rules('OSL-2.1')[0][0]).to eq('OSL-2.1')
      expect(lm.match_rules('OSL v2.1')[0][0]).to eq('OSL-2.1')
      expect(lm.match_rules('uses OSL 2.1 lic')[0][0]).to eq('OSL-2.1')
    end

    it "matches OSL-3.0 rules" do
      expect(lm.match_rules('OSL-3.0')[0][0]).to eq('OSL-3.0')
      expect(lm.match_rules('OSL v3.0')[0][0]).to eq('OSL-3.0')
      expect(lm.match_rules('uses OSL 3.0 lic')[0][0]).to eq('OSL-3.0')

      expect(lm.match_rules('OSL v3')[0][0]).to eq('OSL-3.0')
      expect(lm.match_rules('uses OSL-3 lic')[0][0]).to eq('OSL-3.0')
    end

    it "matches PHP-3.0 rules" do
      expect(lm.match_rules('PHP')[0][0]).to eq('PHP-3.0')
      expect(lm.match_rules('PHP License 3.0')[0][0]).to eq('PHP-3.0')
    end

    it "matches PHP-3.01 rules" do
      expect(lm.match_rules('PHP License version 3.01')[0][0]).to eq('PHP-3.01')
    end

    it "matches PIL rules" do
      expect(lm.match_rules('PIL')[0][0]).to eq('PIL')
      expect(lm.match_rules('Standard PIL License')[0][0]).to eq('PIL')
    end

    it "matches PostgreSQL rules" do
      expect(lm.match_rules('PostgreSQL')[0][0]).to eq('PostgreSQL')
      expect(lm.match_rules('uses PostgreSQL lic')[0][0]).to eq('PostgreSQL')
    end

    it "matches Python-2.0 rules" do
      expect(lm.match_rules('Python v2.0')[0][0]).to eq('Python-2.0')
      expect(lm.match_rules('Python-2.0')[0][0]).to eq('Python-2.0')
      expect(lm.match_rules('uses Python 2.0 lic')[0][0]).to eq('Python-2.0')

      expect(lm.match_rules('Python v2')[0][0]).to eq('Python-2.0')
      expect(lm.match_rules('Python-2')[0][0]).to eq('Python-2.0')
      expect(lm.match_rules('uses Python 2 lic')[0][0]).to eq('Python-2.0')

      expect(lm.match_rules('PSF v2')[0][0]).to eq('Python-2.0')
      expect(lm.match_rules('uses PSF2 lic')[0][0]).to eq('Python-2.0')
      expect(lm.match_rules('Python Software Foundation')[0][0]).to eq('Python-2.0')

      expect(lm.match_rules('http://www.opensource.org/licenses/PythonSoftFoundation.php')[0][0]).to eq('Python-2.0')
      expect(lm.match_rules('same as python2.3'))
      expect(lm.match_rules('http://opensource.org/licenses/PythonSoftFoundation.php')[0][0]).to eq('Python-2.0')
    end

    it "matches Repoze rules" do
      expect(lm.match_rules('Repoze Public License')[0][0]).to eq('Repoze')
    end

    it "matches RPL-1.1 rules" do
      expect(lm.match_rules('RPL-1.1')[0][0]).to eq('RPL-1.1')
      expect(lm.match_rules('RPL v1.1')[0][0]).to eq('RPL-1.1')
      expect(lm.match_rules('uses RPL 1.1 lic')[0][0]).to eq('RPL-1.1')

      expect(lm.match_rules('uses RPL-1')[0][0]).to eq('RPL-1.1')
      expect(lm.match_rules('uses RPL v1')[0][0]).to eq('RPL-1.1')
    end

    it "matches RPL-1.5 rules" do
      expect(lm.match_rules('RPL-1.5')[0][0]).to eq('RPL-1.5')
      expect(lm.match_rules('RPL v1.5')[0][0]).to eq('RPL-1.5')
      expect(lm.match_rules('uses RPL 1.5 lic')[0][0]).to eq('RPL-1.5')
    end

    it "matches QPL-1.0 rules" do
      expect(lm.match_rules('QPL-1.0')[0][0]).to eq('QPL-1.0')
      expect(lm.match_rules('QPL v1.0')[0][0]).to eq('QPL-1.0')
      expect(lm.match_rules('uses QPL 1.0 lic')[0][0]).to eq('QPL-1.0')

      expect(lm.match_rules('QT Public License')[0][0]).to eq('QPL-1.0')
      expect(lm.match_rules('PyQ GENERAL LICENSE')[0][0]).to eq('QPL-1.0')
    end

    it "matches SleepyCat rules" do
      expect(lm.match_rules('Sleepycat')[0][0]).to eq('Sleepycat')
    end

    it "matches SPL-1.0 rules" do
      expect(lm.match_rules('SPLv1.0')[0][0]).to eq('SPL-1.0')
      expect(lm.match_rules('uses SPL-1.0 lic')[0][0]).to eq('SPL-1.0')
      expect(lm.match_rules('Sun Public License')[0][0]).to eq('SPL-1.0')
    end

    it "matches W3C rules" do
      expect(lm.match_rules('W3C')[0][0]).to eq('W3C')
    end

    it "matches OpenSSL rules" do
      expect(lm.match_rules('OpenSSL')[0][0]).to eq('OpenSSL')
    end

    it "matches Unlicense rules" do
      expect(lm.match_rules('UNLICENSE')[0][0]).to eq('Unlicense')
      expect(lm.match_rules('Unlicensed')[0][0]).to eq('Unlicense')
      expect(lm.match_rules('No License')[0][0]).to eq('Unlicense')
      expect(lm.match_rules('Undecided')[0][0]).to eq('Unlicense')
      expect(lm.match_rules('NONLICENSE')[0][0]).to eq('Unlicense')
    end

    it "matches WTFPL " do
      expect(lm.match_rules('WTFPL')[0][0]).to eq('WTFPL')
      expect(lm.match_rules('WTFPLv2')[0][0]).to eq('WTFPL')
      expect(lm.match_rules('Do whatever you want')[0][0]).to eq('WTFPL')
      expect(lm.match_rules('DWTFYW')[0][0]).to eq('WTFPL')
      expect(lm.match_rules('DWYW')[0][0]).to eq('WTFPL')
    end

    it "matches WXwindows rules" do
      expect(lm.match_rules('wxWindows')[0][0]).to eq('WXwindows')
      expect(lm.match_rules('wxWINDOWS LIBRARY license')[0][0]).to eq('WXwindows')
    end

    it "matches X11 rules" do
      expect(lm.match_rules('X11')[0][0]).to eq('X11')
      expect(lm.match_rules('uses X11 lic')[0][0]).to eq('X11')
    end

    it "matches ZPL-1.1 rules" do
      expect(lm.match_rules('ZPL v1.1')[0][0]).to eq('ZPL-1.1')
      expect(lm.match_rules('ZPL-1.1')[0][0]).to eq('ZPL-1.1')
      expect(lm.match_rules('uses ZPL 1.1 lic')[0][0]).to eq('ZPL-1.1')

      expect(lm.match_rules('ZPL v1')[0][0]).to eq('ZPL-1.1')
      expect(lm.match_rules('uses ZPL-1')[0][0]).to eq('ZPL-1.1')
      expect(lm.match_rules('ZPL 1.0')[0][0]).to eq('ZPL-1.1')
    end

    it "matches ZPL-2.1 rules" do
      expect(lm.match_rules('ZPL-2.1')[0][0]).to eq('ZPL-2.1')
      expect(lm.match_rules('ZPL v2.1')[0][0]).to eq('ZPL-2.1')
      expect(lm.match_rules('uses ZPL 2.1 lic')[0][0]).to eq('ZPL-2.1')

      expect(lm.match_rules('ZPL v2')[0][0]).to eq('ZPL-2.1')
      expect(lm.match_rules('ZPL-2')[0][0]).to eq('ZPL-2.1')
      expect(lm.match_rules('uses ZPL 2 lic')[0][0]).to eq('ZPL-2.1')
      expect(lm.match_rules('ZPL/2.1')[0][0]).to eq('ZPL-2.1')
      expect(lm.match_rules('ZPL 2.0')[0][0]).to eq('ZPL-2.1')
      expect(lm.match_rules('ZOPE PUBLIC LICENSE')[0][0]).to eq('ZPL-2.1')
      expect(lm.match_rules('ZPL')[0][0]).to eq('ZPL-2.1')
    end

    it "matches ZLIB rules" do
      expect(lm.match_rules('ZLIB')[0][0]).to eq('ZLIB')
      expect(lm.match_rules('uses ZLIB license')[0][0]).to eq('ZLIB')
    end

    it "matches ZLIB-acknowledgement rules" do
      expect(lm.match_rules('ZLIB/LIBPNG')[0][0]).to eq('zlib-acknowledgement')
    end
  end
end

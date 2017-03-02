require 'spec_helper'

describe LicenseMatcher do
  lm = LicenseMatcher.new #initialization is slow, just init once

  describe "match_rules" do
    it "matches AAL" do
      expect(lm.match_rules('AAL').first.first).to eq('aal');
      expect(lm.match_rules('It uses AAL license for source code').first.first).to eq('aal')
      expect(lm.match_rules('(C) Attribution Assurance License 2011').first.first).to eq('aal')
    end
   
    it "matches AFL" do
      expect(lm.match_rules('afl-1.1').first.first).to eq('afl-1.1')
      expect(lm.match_rules('Released under AFLv1 license').first.first).to eq('afl-1.1')
      expect(lm.match_rules('AFLv1.2 license').first.first).to eq('afl-1.2')
      expect(lm.match_rules('licensed under afl-1.2 License').first.first).to eq('afl-1.2')
      expect(lm.match_rules('AFL-2.0').first.first).to eq('afl-2.0')
      expect(lm.match_rules('licensed as AFLv2 license').first.first).to eq('afl-2.0')
      expect(lm.match_rules('AFL-2.1').first.first).to eq('afl-2.1')
      expect(lm.match_rules('released under AFLv2.1 lic').first.first).to eq('afl-2.1')
      expect(lm.match_rules('AFLv3.0').first.first).to eq('afl-3.0')
      expect(lm.match_rules('uses AFLv3.0 license').first.first).to eq('afl-3.0')
      expect(lm.match_rules('Academic Free License').first.first).to eq('afl-3.0')

      expect(lm.match_rules('AFL-v3.0')[0][0]).to eq('afl-3.0')
      expect(lm.match_rules('AFL')[0][0]).to eq('afl-3.0')
      expect(lm.match_rules('Academic-Free-License-(AFL)')[0][0]).to eq('afl-3.0')
    end

    it "matches AGPL licenses" do
      expect(lm.match_rules('licensed under AGPL')[0][0]).to eq('agpl-1.0')
      expect(lm.match_rules('AGPLv1')[0][0]).to eq('agpl-1.0')
      expect(lm.match_rules('Affero General Public license 1')[0][0]).to eq('agpl-1.0')

      expect(lm.match_rules('AGPL-3')[0][0]).to eq('agpl-3.0')
      expect(lm.match_rules('It uses AGPLv3.0')[0][0]).to eq('agpl-3.0')
      expect(lm.match_rules('GNU Affero General Public License v3 or later (AGPLv3+)')[0][0]).to eq('agpl-3.0')

      expect(lm.match_rules('Affero General Public License, version 3.0')[0][0]).to eq('agpl-3.0')
      expect(lm.match_rules('GNU Affero General Public License, version 3')[0][0]).to eq('agpl-3.0')
      expect(lm.match_rules('GNU AGPL v3')[0][0]).to eq('agpl-3.0')
      expect(lm.match_rules('AGPL v3+')[0][0]).to eq('agpl-3.0')

      expect(lm.match_rules('Lesser Affero General Public License v3')[0][0]).to eq('agpl-3.0')
      expect(lm.match_rules('https://gnu.org/licenses/agpl.html')[0][0]).to eq('agpl-3.0')
      expect(lm.match_rules('Affero General Public License')[0][0]).to eq('agpl-3.0')
      expect(lm.match_rules('Software license AGPL version 3. ')[0][0]).to eq('agpl-3.0')
      expect(lm.match_rules('GNU AFFERO 3')[0][0]).to eq('agpl-3.0')
    end

    it "matches Aladdin rules" do
      expect(lm.match_rules('AFPL')[0][0]).to eq('aladdin')
      expect(lm.match_rules('(AFPL)')[0][0]).to eq('aladdin')

      expect(lm.match_rules('Aladdin Free Public License')[0][0]).to eq('aladdin')
    end

    it "matches Amazon rules" do
      expect(lm.match_rules('Amazon Software License')[0][0]).to eq('amazon')
    end

    it "matches APACHE licenses" do
      expect(lm.match_rules('APACHEv1').first.first ).to eq('apache-1.0')
      expect(lm.match_rules('Lic as APACHE-V1').first.first).to eq('apache-1.0')
      expect(lm.match_rules('APacheV1 is +100').first.first).to eq('apache-1.0')
      expect(lm.match_rules('Released under Apache-1.0').first.first).to eq('apache-1.0')
      expect(lm.match_rules('uses Apache 1.0 license').first.first).to eq('apache-1.0')

      expect(lm.match_rules('APACHE-1.1').first.first).to eq('apache-1.1')
      expect(lm.match_rules('Apache v1.1 license').first.first).to eq('apache-1.1')
      expect(lm.match_rules('uses Apache-1.1 lic').first.first).to eq('apache-1.1')

      expect(lm.match_rules('APACHEv2').first.first).to eq('apache-2.0')
      expect(lm.match_rules('APACHE-2').first.first).to eq('apache-2.0')
      expect(lm.match_rules('Apache v2').first.first).to eq('apache-2.0')
      expect(lm.match_rules('uses Apache 2.0').first.first).to eq('apache-2.0')
      expect(lm.match_rules('Apache 2 is it').first.first).to eq('apache-2.0')
      expect(lm.match_rules('Apache license version 2.0').first.first).to eq('apache-2.0')

      expect(lm.match_rules('Apache License 2.0')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('Apache License, Version 2.0')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('Apache Software License')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('License :: OSI Approved :: Apache Software License')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('Apache License v2.0')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('Apache License (2.0)')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('Apache license')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('Apache')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('Apache Open Source License 2.0')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('Apapche-2.0')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('AL-2.0')[0][0]).to eq('apache-2.0')
      expect(lm.match_rules('the Apache License v2 ')[0][0]).to eq('apache-2.0')
    end

    it "matches APL licenses" do
      expect(lm.match_rules('APLv1').first.first).to eq('apl-1.0')
      expect(lm.match_rules('APL-1').first.first).to eq('apl-1.0')
      expect(lm.match_rules('APL-v1').first.first).to eq('apl-1.0')
      expect(lm.match_rules('lic APLv1 lic').first.first).to eq('apl-1.0')
      expect(lm.match_rules('APL v1').first.first).to eq('apl-1.0')
      expect(lm.match_rules('APL 1.0').first.first).to eq('apl-1.0')
    end

    it "matches APLS-1.0 licenses" do
      expect(lm.match_rules('APSLv1.0').first.first).to eq('apsl-1.0')
      expect(lm.match_rules('APSL 1.0').first.first).to eq('apsl-1.0')
      expect(lm.match_rules('lic apsl-1.0 lic').first.first).to eq('apsl-1.0')
      expect(lm.match_rules('lic APSL-v1.0').first.first).to eq('apsl-1.0')

      expect(lm.match_rules('APSLv1')[0][0]).to eq('apsl-1.0')
      expect(lm.match_rules('APSL-v1')[0][0]).to eq('apsl-1.0')
      expect(lm.match_rules('APSL v1')[0][0]).to eq('apsl-1.0')

      expect(lm.match_rules('APPLE PUBLIC source')[0][0]).to eq('apsl-1.0')
    end

    it "matches apsl-1.1 licenses" do
      expect(lm.match_rules('APSLv1.1')[0][0]).to eq('apsl-1.1')
      expect(lm.match_rules('APSL 1.1')[0][0]).to eq('apsl-1.1')
      expect(lm.match_rules('APSL v1.1')[0][0]).to eq('apsl-1.1')
      expect(lm.match_rules('lic APSL v1.1 lic')[0][0]).to eq('apsl-1.1')
    end

    it "matches apsl-1.2 licenses" do
      expect(lm.match_rules('APSLv1.2')[0][0]).to eq('apsl-1.2')
      expect(lm.match_rules('apsl-1.2')[0][0]).to eq('apsl-1.2')
      expect(lm.match_rules('APSL v1.2')[0][0]).to eq('apsl-1.2')
      expect(lm.match_rules('APSL 1.2')[0][0]).to eq('apsl-1.2')
      expect(lm.match_rules('lic APSL 1.2 lic')[0][0]).to eq('apsl-1.2')
    end

    it "matches apsl-2.0 licenses" do
      expect(lm.match_rules('APSLv2.0')[0][0]).to eq('apsl-2.0')
      expect(lm.match_rules('apsl-2.0')[0][0]).to eq('apsl-2.0')
      expect(lm.match_rules('APSL v2.0')[0][0]).to eq('apsl-2.0')
      expect(lm.match_rules('APSL 2.0')[0][0]).to eq('apsl-2.0')
      expect(lm.match_rules('APSLv2')[0][0]).to eq('apsl-2.0')
      expect(lm.match_rules('APSL 2')[0][0]).to eq('apsl-2.0')
      expect(lm.match_rules('lic APSL 2.0 lic')[0][0]).to eq('apsl-2.0')
    end

    it "matches Artistic-1.0 licenses" do
      expect(lm.match_rules('ArtisticV1.0')[0][0]).to eq('artistic-1.0')
      expect(lm.match_rules('Artistic V1.0')[0][0]).to eq('artistic-1.0')
      expect(lm.match_rules('Artistic 1.0')[0][0]).to eq('artistic-1.0')
    
      expect(lm.match_rules('ArtisticV1')[0][0]).to eq('artistic-1.0')
      expect(lm.match_rules('Artistic V1')[0][0]).to eq('artistic-1.0')
      expect(lm.match_rules('Artistic 1')[0][0]).to eq('artistic-1.0')
      expect(lm.match_rules('uses ArtisticV1 license')[0][0]).to eq('artistic-1.0')
    end

    it "matches Artistic-2.0 licenses" do
      expect(lm.match_rules('ArtisticV2.0')[0][0]).to eq('artistic-2.0')
      expect(lm.match_rules('Artistic V2.0')[0][0]).to eq('artistic-2.0')
      expect(lm.match_rules('Artistic 2.0')[0][0]).to eq('artistic-2.0')
      expect(lm.match_rules('Artistic-2.0')[0][0]).to eq('artistic-2.0')

      expect(lm.match_rules('ArtisticV2')[0][0]).to eq('artistic-2.0')
      expect(lm.match_rules('Artistic 2')[0][0]).to eq('artistic-2.0')
      expect(lm.match_rules('uses Artistic 2 license')[0][0]).to eq('artistic-2.0')

      expect(lm.match_rules('uses Artistic License')[0][0]).to eq('artistic-2.0')
      expect(lm.match_rules('Artistic_2_0')[0][0]).to eq('artistic-2.0')
    end

    it "matches Artistic-1.0-Perl licenses" do
      expect(lm.match_rules('Artistic-1.0-Perl')[0][0]).to eq('artistic-1.0-perl')
      expect(lm.match_rules('uses Artistic-1.0-Perl lic')[0][0]).to eq('artistic-1.0-perl')
      expect(lm.match_rules('Artistic 1.0-Perl')[0][0]).to eq('artistic-1.0-perl')
      expect(lm.match_rules('PerlArtistic')[0][0]).to eq('artistic-1.0-perl')
    end

    it "matches BeerWare" do
      expect(lm.match_rules('beerWare')[0][0]).to eq('beerware')
      expect(lm.match_rules('Rel as Beer-Ware lic')[0][0]).to eq('beerware')
      expect(lm.match_rules('BEER License')[0][0]).to eq('beerware')
      expect(lm.match_rules('BEER')[0][0]).to eq('beerware')
      expect(lm.match_rules('Free as in beer.')[0][0]).to eq('beerware')
    end

    it "matches BitTorrent-1.1 rules" do
      expect(lm.match_rules('BitTorrent Open Source License')[0][0]).to eq('bittorrent-1.1')
    end

    it "matches to 0BSD rules" do
      expect(lm.match_rules('0BSD')[0][0]).to eq('0bsd')
    end

    it "matches to BSD-2" do
      expect(lm.match_rules('BSD2')[0][0]).to eq('bsd-2-clause')
      expect(lm.match_rules('BSD-2')[0][0]).to eq('bsd-2-clause')
      expect(lm.match_rules('Uses BSD v2 lic')[0][0]).to eq('bsd-2-clause')

      expect(lm.match_rules('FreeBSD')[0][0]).to eq('bsd-2-clause')
      expect(lm.match_rules('BSDLv2')[0][0]).to eq('bsd-2-clause')
    end

    it "matches to BSD-3" do
      expect(lm.match_rules('BSD3')[0][0]).to eq('bsd-3-clause')
      expect(lm.match_rules('BSD v3')[0][0]).to eq('bsd-3-clause')
      expect(lm.match_rules('BSD3')[0][0]).to eq('bsd-3-clause')
      expect(lm.match_rules('BSD3 clause')[0][0]).to eq('bsd-3-clause')
      expect(lm.match_rules('aaa three-clause BSD license aaa')[0][0]).to eq('bsd-3-clause')
    end

    it "matches to BSD-4" do
      expect(lm.match_rules('BSDv4')[0][0]).to eq('bsd-4-clause')
      expect(lm.match_rules('BSD v4')[0][0]).to eq('bsd-4-clause')
      expect(lm.match_rules('BSD4 Clause')[0][0]).to eq('bsd-4-clause')
      expect(lm.match_rules('BSD LISENCE')[0][0]).to eq('bsd-4-clause')
      expect(lm.match_rules('uses BSD4 clause')[0][0]).to eq('bsd-4-clause')

      expect(lm.match_rules('http://en.wikipedia.org/wiki/BSD_licenses')[0][0]).to eq('bsd-4-clause')
    end

    it "matches to bsl-1.0" do
      expect(lm.match_rules('BSLv1.0')[0][0]).to eq('bsl-1.0')
      expect(lm.match_rules('BSL-v1')[0][0]).to eq('bsl-1.0')
      expect(lm.match_rules('uses bsl-1.0 lic')[0][0]).to eq('bsl-1.0')
      expect(lm.match_rules('Boost License 1.0')[0][0]).to eq('bsl-1.0')
    end

    it "matches to cc0-1.0" do
      expect(lm.match_rules('cc0-1.0')[0][0]).to eq('cc0-1.0')
      expect(lm.match_rules('CC0 1.0')[0][0]).to eq('cc0-1.0')
      expect(lm.match_rules('uses CC0-v1.0 lic')[0][0]).to eq('cc0-1.0')

      expect(lm.match_rules('CC0v1')[0][0]).to eq('cc0-1.0')
      expect(lm.match_rules('CC0-v1')[0][0]).to eq('cc0-1.0')
      expect(lm.match_rules('uses CC0 v1 license')[0][0]).to eq('cc0-1.0')
      expect(lm.match_rules('http://creativecommons.org/publicdomain/zero/1.0/')[0][0]).to eq('cc0-1.0')
      expect(lm.match_rules('cc-zero')[0][0]).to eq('cc0-1.0')
    end

    it "matches to cc-by-1.0" do
      expect(lm.match_rules('cc-by-1.0')[0][0]).to eq('cc-by-1.0')
      expect(lm.match_rules('CC BY 1.0')[0][0]).to eq('cc-by-1.0')
      expect(lm.match_rules('uses CC BY-1.0 lic')[0][0]).to eq('cc-by-1.0')

      expect(lm.match_rules('CC-BY-v1')[0][0]).to eq('cc-by-1.0')
      expect(lm.match_rules('uses CC BY v1 lic')[0][0]).to eq('cc-by-1.0')

    end

    it "matches to cc-by-2.0" do
      expect(lm.match_rules('CC-by-2.0')[0][0]).to eq('cc-by-2.0')
      expect(lm.match_rules('CC by v2.0')[0][0]).to eq('cc-by-2.0')
      expect(lm.match_rules('uses cc-by-2.0 lic')[0][0]).to eq('cc-by-2.0')

      expect(lm.match_rules('CC-BY-2')[0][0]).to eq('cc-by-2.0')
      expect(lm.match_rules('CC-by v2')[0][0]).to eq('cc-by-2.0')
      expect(lm.match_rules('uses CC-BY-2 lic')[0][0]).to eq('cc-by-2.0')
    end

    it "matches to cc-by-2.5" do
      expect(lm.match_rules('cc-by-2.5')[0][0]).to eq('cc-by-2.5')
      expect(lm.match_rules('CC BY 2.5')[0][0]).to eq('cc-by-2.5')
      expect(lm.match_rules('CC-BY v2.5')[0][0]).to eq('cc-by-2.5')
      expect(lm.match_rules('uses cc-by-2.5 lic')[0][0]).to eq('cc-by-2.5')
    end

    it "matches to cc-by-3.0" do
      expect(lm.match_rules('cc-by-3.0')[0][0]).to eq('cc-by-3.0')
      expect(lm.match_rules('CC BY 3.0')[0][0]).to eq('cc-by-3.0')
      expect(lm.match_rules('CC-BY v3.0')[0][0]).to eq('cc-by-3.0')
      expect(lm.match_rules('uses cc-by-3.0')[0][0]).to eq('cc-by-3.0')

      expect(lm.match_rules('CC-BY-3')[0][0]).to eq('cc-by-3.0')
      expect(lm.match_rules('CC-BY v3')[0][0]).to eq('cc-by-3.0')
      expect(lm.match_rules('(CC-BY) v3')[0][0]).to eq('cc-by-3.0')
      expect(lm.match_rules('Creative Common "Attribution" license (CC-BY) v3')[0][0]).to eq('cc-by-3.0')
      expect(lm.match_rules('Creative Commons BY 3.0')[0][0]).to eq('cc-by-3.0')
      expect(lm.match_rules('Creative Commons License <http://creativecommons.org/licenses/by/3.0/')[0][0]).to eq('cc-by-3.0')
      expect(lm.match_rules('See: https://creativecommons.org/licenses/by/3.0/')[0][0]).to eq('cc-by-3.0')

    end

    it "matches to cc-by-4.0" do
      expect(lm.match_rules('cc-by-4.0')[0][0]).to eq('cc-by-4.0')
      expect(lm.match_rules('CC BY 4.0')[0][0]).to eq('cc-by-4.0')
      expect(lm.match_rules('uses cc-by-4.0')[0][0]).to eq('cc-by-4.0')

      expect(lm.match_rules('CC-BY-4')[0][0]).to eq('cc-by-4.0')
      expect(lm.match_rules('CC-BY v4')[0][0]).to eq('cc-by-4.0')

      expect(lm.match_rules('CREATIVE COMMONS ATTRIBUTION v4.0')[0][0]).to eq('cc-by-4.0')
    end

    it "matches to cc-by-sa-1.0" do
      expect(lm.match_rules('cc-by-sa-1.0')[0][0]).to eq('cc-by-sa-1.0')
      expect(lm.match_rules('CC BY-SA 1.0')[0][0]).to eq('cc-by-sa-1.0')
      expect(lm.match_rules('uses CC BY-SA v1.0')[0][0]).to eq('cc-by-sa-1.0')

      expect(lm.match_rules('CC-BY-SA v1')[0][0]).to eq('cc-by-sa-1.0')
      expect(lm.match_rules('CC BY-SA-1')[0][0]).to eq('cc-by-sa-1.0')
    end

    it "matches to cc-by-sa-2.0" do
      expect(lm.match_rules('CC-BY-SA 2.0')[0][0]).to eq('cc-by-sa-2.0')
      expect(lm.match_rules('CC BY-SA-2.0')[0][0]).to eq('cc-by-sa-2.0')
      expect(lm.match_rules('CC BY-SA v2.0')[0][0]).to eq('cc-by-sa-2.0')
      expect(lm.match_rules('uses CC BY-SA 2.0 lic')[0][0]).to eq('cc-by-sa-2.0')

      expect(lm.match_rules('CC-BY-SA-2')[0][0]).to eq('cc-by-sa-2.0')
      expect(lm.match_rules('CC BY-SA v2')[0][0]).to eq('cc-by-sa-2.0')
    end

    it "matches to cc-by-sa-2.5" do
      expect(lm.match_rules('cc-by-sa-2.5')[0][0]).to eq('cc-by-sa-2.5')
      expect(lm.match_rules('CC BY-SA 2.5')[0][0]).to eq('cc-by-sa-2.5')
      expect(lm.match_rules('CC-BY-SA v2.5')[0][0]).to eq('cc-by-sa-2.5')
      expect(lm.match_rules('uses CC BY-SA 2.5')[0][0]).to eq('cc-by-sa-2.5')
    end

    it "matches to cc-by-sa-3.0" do
      expect(lm.match_rules('CC BY-SA 3.0')[0][0]).to eq('cc-by-sa-3.0')
      expect(lm.match_rules('cc-by-sa-3.0')[0][0]).to eq('cc-by-sa-3.0')
      expect(lm.match_rules('CC-BY-SA v3.0')[0][0]).to eq('cc-by-sa-3.0')
      expect(lm.match_rules('uses CC BY-SA 3.0 lic')[0][0]).to eq('cc-by-sa-3.0')

      expect(lm.match_rules('CC-BY-SA-3')[0][0]).to eq('cc-by-sa-3.0')
      expect(lm.match_rules('CC BY-SA v3')[0][0]).to eq('cc-by-sa-3.0')
      expect(lm.match_rules('uses CC BY-SA-3')[0][0]).to eq('cc-by-sa-3.0')
      expect(lm.match_rules('http://creativecommons.org/licenses/by-sa/3.0/')[0][0]).to  eq('cc-by-sa-3.0')

    end

    it "matches to cc-by-sa-4.0" do
      expect(lm.match_rules('CC BY-SA 4.0')[0][0]).to eq('cc-by-sa-4.0')
      expect(lm.match_rules('CC-BY-SA v4.0')[0][0]).to eq('cc-by-sa-4.0')
      expect(lm.match_rules('uses CC BY SA 4.0 lic')[0][0]).to eq('cc-by-sa-4.0')

      expect(lm.match_rules('CC-BY-SA v4')[0][0]).to eq('cc-by-sa-4.0')
      expect(lm.match_rules('CC BY-SA 4')[0][0]).to eq('cc-by-sa-4.0')
      expect(lm.match_rules('uses CC BY-SA v4 lic')[0][0]).to eq('cc-by-sa-4.0')

      expect(lm.match_rules('CCSA-4.0')[0][0]).to eq('cc-by-sa-4.0')
      expect(lm.match_rules('uses CCSA-4.0 lic')[0][0]).to eq('cc-by-sa-4.0')
    end

    it "matches to cc-by-nc-1.0" do
      expect(lm.match_rules('CC BY-NC 1.0')[0][0]).to eq('cc-by-nc-1.0')
      expect(lm.match_rules('CC BY NC v1.0')[0][0]).to eq('cc-by-nc-1.0')
      expect(lm.match_rules('uses CC-BY-NC v1.0 lic')[0][0]).to eq('cc-by-nc-1.0')

      expect(lm.match_rules('CC-BY-NC-1')[0][0]).to eq('cc-by-nc-1.0')
      expect(lm.match_rules('CC BY-NC v1')[0][0]).to eq('cc-by-nc-1.0')
      expect(lm.match_rules('uses CC-BY-NC-1 lic')[0][0]).to eq('cc-by-nc-1.0')
    end

    it "matches to cc-by-nc-2.0" do
      expect(lm.match_rules('CC-BY-NC 2.0')[0][0]).to eq('cc-by-nc-2.0')
      expect(lm.match_rules('CC-BY-NCv2.0')[0][0]).to eq('cc-by-nc-2.0')
      expect(lm.match_rules('uses CC-BY-NC 2.0 lic')[0][0]).to eq('cc-by-nc-2.0')
    end

    it "matches to cc-by-nc-2.5" do
      expect(lm.match_rules('CC-BY-NC 2.5')[0][0]).to eq('cc-by-nc-2.5')
      expect(lm.match_rules('CC BY-NC v2.5')[0][0]).to eq('cc-by-nc-2.5')
      expect(lm.match_rules('cc-by-nc-2.5')[0][0]).to eq('cc-by-nc-2.5')
      expect(lm.match_rules('uses CC-BY-NC 2.5 lic')[0][0]).to eq('cc-by-nc-2.5')
    end

    it "matches to cc-by-nc-3.0" do
      expect(lm.match_rules('CC-BY-NC 3.0')[0][0]).to eq('cc-by-nc-3.0')
      expect(lm.match_rules('CC BY-NC v3.0')[0][0]).to eq('cc-by-nc-3.0')
      expect(lm.match_rules('uses CC BY-NC3.0 lic')[0][0]).to eq('cc-by-nc-3.0')
      
      expect(lm.match_rules('CC BY NC v3')[0][0]).to eq('cc-by-nc-3.0')
      expect(lm.match_rules('CC-BY-NC-3')[0][0]).to eq('cc-by-nc-3.0')
      expect(lm.match_rules('uses CC-BY-NC v3 lic')[0][0]).to eq('cc-by-nc-3.0')
    end

    it "matches to cc-by-nc-4.0" do
      expect(lm.match_rules('CC-BY-NC 4.0')[0][0]).to eq('cc-by-nc-4.0')
      expect(lm.match_rules('CC BY-NC v4.0')[0][0]).to eq('cc-by-nc-4.0')
      expect(lm.match_rules('uses CC-BY-NC 4.0 lic')[0][0]).to eq('cc-by-nc-4.0')

      expect(lm.match_rules('CC-BY-NC v4')[0][0]).to eq('cc-by-nc-4.0')
      expect(lm.match_rules('CC BY-NC-4')[0][0]).to eq('cc-by-nc-4.0')
      expect(lm.match_rules('uses CC-BY-NC 4 lic')[0][0]).to eq('cc-by-nc-4.0')
      expect(lm.match_rules('http://creativecommons.org/licenses/by-nc/3.0/')[0][0]).to eq('cc-by-nc-4.0')
    end

    it "matches to cc-by-nc-sa-1.0" do
      expect(lm.match_rules('cc-by-nc-sa-1.0')[0][0]).to eq('cc-by-nc-sa-1.0')
      expect(lm.match_rules('CC BY-NC SA v1.0')[0][0]).to eq('cc-by-nc-sa-1.0')
      expect(lm.match_rules('uses CC BY-NC-SA 1.0 lic')[0][0]).to eq('cc-by-nc-sa-1.0')

      expect(lm.match_rules('CC BY-NC-SA v1')[0][0]).to eq('cc-by-nc-sa-1.0')
      expect(lm.match_rules('CC BY-NC-SA-1')[0][0]).to eq('cc-by-nc-sa-1.0')
      expect(lm.match_rules('uses CC-BY-NC-SA-1 lic')[0][0]).to eq('cc-by-nc-sa-1.0')
    end

    it "matches to cc-by-nc-sa-2.0" do
      expect(lm.match_rules('CC BY-NC-SA 2.0')[0][0]).to eq('cc-by-nc-sa-2.0')
      expect(lm.match_rules('CC-BY-NC-SA-v2.0')[0][0]).to eq('cc-by-nc-sa-2.0')
      expect(lm.match_rules('uses CC-BY-NC-SA 2.0 lic')[0][0]).to eq('cc-by-nc-sa-2.0')
    end

    it "matches to cc-by-nc-sa-2.5" do
      expect(lm.match_rules('cc-by-nc-sa-2.5')[0][0]).to eq('cc-by-nc-sa-2.5')
      expect(lm.match_rules('CC BY-NC-SA v2.5')[0][0]).to eq('cc-by-nc-sa-2.5')
      expect(lm.match_rules('uses CC BY-NC SA2.5')[0][0]).to eq('cc-by-nc-sa-2.5')
    end

    it "matches to cc-by-nc-sa-3.0" do
      expect(lm.match_rules('cc-by-nc-sa-3.0')[0][0]).to eq('cc-by-nc-sa-3.0')
      expect(lm.match_rules('CC BY-NC-SA v3.0')[0][0]).to eq('cc-by-nc-sa-3.0')
      expect(lm.match_rules('uses CC BY NC-SA-3.0')[0][0]).to eq('cc-by-nc-sa-3.0')


      expect(lm.match_rules('CC BY-NC-SA v3')[0][0]).to eq('cc-by-nc-sa-3.0')
      expect(lm.match_rules('uses CC-BY-NC-SA-3 lic')[0][0]).to eq('cc-by-nc-sa-3.0')

      expect(lm.match_rules('BY-NC-SA v3.0')[0][0]).to eq('cc-by-nc-sa-3.0')
      expect(lm.match_rules('as By-NC-SA 3.0 lic')[0][0]).to eq('cc-by-nc-sa-3.0')
      expect(lm.match_rules('http://creativecommons.org/licenses/by-nc-sa/3.0/us/')[0][0]).to eq('cc-by-nc-sa-3.0')

    end

    it "matches to cc-by-nc-sa-4.0" do
      expect(lm.match_rules('cc-by-nc-sa-4.0')[0][0]).to eq('cc-by-nc-sa-4.0')
      expect(lm.match_rules('CC BY-NC SAv4.0')[0][0]).to eq('cc-by-nc-sa-4.0')
      expect(lm.match_rules('uses CC-BY-NC-SA v4.0')[0][0]).to eq('cc-by-nc-sa-4.0')

      expect(lm.match_rules('CC-BY-NC-SA v4')[0][0]).to eq('cc-by-nc-sa-4.0')
      expect(lm.match_rules('CC BY-NC-SA-4')[0][0]).to eq('cc-by-nc-sa-4.0')
      expect(lm.match_rules('uses CC-BY-NC-SA-v4 lic')[0][0]).to eq('cc-by-nc-sa-4.0')
      expect(lm.match_rules('BY-NC-SA 4.0')[0][0]).to eq('cc-by-nc-sa-4.0')
    end

    it "matches to cc-by-nd-1.0" do
      expect(lm.match_rules('cc-by-nd-1.0')[0][0]).to eq('cc-by-nd-1.0')
      expect(lm.match_rules('CC-BY-ND v1.0')[0][0]).to eq('cc-by-nd-1.0')
      expect(lm.match_rules('uses CC BY-ND 1.0 lic')[0][0]).to eq('cc-by-nd-1.0')
    end

    it "matches to cc-by-nd-2.0" do
      expect(lm.match_rules('cc-by-nd-2.0')[0][0]).to eq('cc-by-nd-2.0')
      expect(lm.match_rules('CC-BY-ND v2.0')[0][0]).to eq('cc-by-nd-2.0')
      expect(lm.match_rules('uses CC BY-ND 2.0 lic')[0][0]).to eq('cc-by-nd-2.0')
    end

    it "matches to cc-by-nd-2.5" do
      expect(lm.match_rules('cc-by-nd-2.5')[0][0]).to eq('cc-by-nd-2.5')
      expect(lm.match_rules('CC-BY-ND v2.5')[0][0]).to eq('cc-by-nd-2.5')
      expect(lm.match_rules('uses CC BY-ND 2.5 lic')[0][0]).to eq('cc-by-nd-2.5')
    end

    it "matches to cc-by-nd-3.0" do
      expect(lm.match_rules('cc-by-nd-3.0')[0][0]).to eq('cc-by-nd-3.0')
      expect(lm.match_rules('CC-BY-ND v3.0')[0][0]).to eq('cc-by-nd-3.0')
      expect(lm.match_rules('uses CC BY-ND 3.0 lic')[0][0]).to eq('cc-by-nd-3.0')
    end

    it "matches to cc-by-nd-4.0" do
      expect(lm.match_rules('cc-by-nd-4.0')[0][0]).to eq('cc-by-nd-4.0')
      expect(lm.match_rules('CC-BY-ND v4.0')[0][0]).to eq('cc-by-nd-4.0')
      expect(lm.match_rules('uses CC BY-ND 4.0 lic')[0][0]).to eq('cc-by-nd-4.0')
      expect(lm.match_rules('CC BY-ND 4.0')[0][0]).to eq('cc-by-nd-4.0')
    end

    it "matches CC-BY-NC-ND-3.0 rules" do
      expect(lm.match_rules('CC-BY-NC-ND-3.0')[0][0]).to eq('cc-by-nc-nd-3.0')
    end

    it "matches CC-BY-NC-ND-4.0 rules" do
      expect(lm.match_rules('CC-BY-NC-ND-4.0')[0][0]).to eq('cc-by-nc-nd-4.0')
    end

    it "matches cddl-1.0 rules" do
      expect(lm.match_rules('CDDL-V1.0')[0][0]).to eq('cddl-1.0')
      expect(lm.match_rules('CDDL 1.0')[0][0]).to eq('cddl-1.0')
      expect(lm.match_rules('uses CDDLv1.0')[0][0]).to eq('cddl-1.0')

      expect(lm.match_rules('CDDL v1')[0][0]).to eq('cddl-1.0')
      expect(lm.match_rules('CDDL-1')[0][0]).to eq('cddl-1.0')
      expect(lm.match_rules('uses CDDL v1 lic')[0][0]).to eq('cddl-1.0')

      expect(lm.match_rules('CDDL License')[0][0]).to eq('cddl-1.0')
      expect(lm.match_rules('COMMON DEVELOPMENT AND DISTRIBUTION LICENSE')[0][0]).to eq('cddl-1.0')
    end

    it "matches cecill-b rules" do
      expect(lm.match_rules('cecill-b')[0][0]).to eq('cecill-b')
      expect(lm.match_rules('CECILL B')[0][0]).to eq('cecill-b')
      expect(lm.match_rules('uses CECILL_B lic')[0][0]).to eq('cecill-b')
      expect(lm.match_rules('CECILLB')[0][0]).to eq('cecill-b')
    end

    it "matches cecill-c rules" do
      expect(lm.match_rules('cecill-c')[0][0]).to eq('cecill-c')
      expect(lm.match_rules('CECILL C')[0][0]).to eq('cecill-c')
      expect(lm.match_rules('uses cecill-c lic')[0][0]).to eq('cecill-c')
      expect(lm.match_rules('CECILLC')[0][0]).to eq('cecill-c')
    end

    it "matches cecill-1.0 rules" do
      expect(lm.match_rules('cecill-1.0')[0][0]).to eq('cecill-1.0')
      expect(lm.match_rules('CECILL v1.0')[0][0]).to eq('cecill-1.0')
      expect(lm.match_rules('uses CECILL 1.0 lic')[0][0]).to eq('cecill-1.0')

      expect(lm.match_rules('CECILL-1')[0][0]).to eq('cecill-1.0')
      expect(lm.match_rules('CECILL v1')[0][0]).to eq('cecill-1.0')
      expect(lm.match_rules('uses CECILL v1 lic')[0][0]).to eq('cecill-1.0')

      expect(lm.match_rules('http://www.cecill.info')[0][0]).to eq('cecill-1.0')
    end

    it "matches cecill-2.1 rules" do
      expect(lm.match_rules('cecill-2.1')[0][0]).to eq('cecill-2.1')
      expect(lm.match_rules('CECILL v2.1')[0][0]).to eq('cecill-2.1')
      expect(lm.match_rules('uses CECILL 2.1 lic')[0][0]).to eq('cecill-2.1')

      expect(lm.match_rules('Cecill Version 2.1')[0][0]).to eq('cecill-2.1')
    end
    
    it "matches cpal-1.0 rules" do
      expect(lm.match_rules('Common Public Attribution License 1.0')[0][0]).to eq('cpal-1.0')
      expect(lm.match_rules('cpal-1.0')[0][0]).to eq('cpal-1.0')
      expect(lm.match_rules('CPAL')[0][0]).to eq('cpal-1.0')
    end

    it "matches cpl-1.0 rules" do
      expect(lm.match_rules('cpl-1.0')[0][0]).to eq('cpl-1.0')
      expect(lm.match_rules('CPL v1.0')[0][0]).to eq('cpl-1.0')
      expect(lm.match_rules('uses CPL 1.0 lic')[0][0]).to eq('cpl-1.0')

      expect(lm.match_rules('CPL-v1')[0][0]).to eq('cpl-1.0')
      expect(lm.match_rules('CPL v1')[0][0]).to eq('cpl-1.0')
      expect(lm.match_rules('uses CPL-1 lic')[0][0]).to eq('cpl-1.0')

      expect(lm.match_rules('uses COMMON PUBLIC LICENSE')[0][0]).to eq('cpl-1.0')
    end

    it "matches dbad rules" do
      expect(lm.match_rules('DONT BE A DICK PUBLIC LICENSE')[0][0]).to eq('dbad')
      expect(lm.match_rules('dbad')[0][0]).to eq('dbad')
      expect(lm.match_rules('dbad-license')[0][0]).to eq('dbad')
      expect(lm.match_rules('dbad-1')[0][0]).to eq('dbad')
      expect(lm.match_rules('DBAP License')[0][0]).to eq('dbad')
    end

    it "matches d-fsl-1.0" do
      expect(lm.match_rules('DFSL-v1.0')[0][0]).to eq('d-fsl-1.0')
      expect(lm.match_rules('D-FSL 1.0')[0][0]).to eq('d-fsl-1.0')
      expect(lm.match_rules('uses D-FSL v1.0 lic')[0][0]).to eq('d-fsl-1.0')

      expect(lm.match_rules('D-FSL v1')[0][0]).to eq('d-fsl-1.0')
      expect(lm.match_rules('DFSL-1')[0][0]).to eq('d-fsl-1.0')
      expect(lm.match_rules('uses DFSL v1 lic')[0][0]).to eq('d-fsl-1.0')

      expect(lm.match_rules('German Free Software')[0][0]).to eq('d-fsl-1.0')
      expect(lm.match_rules('Deutsche Freie Software Lizenz')[0][0]).to eq('d-fsl-1.0')
    end

    it "matches ecl-1.0" do
      expect(lm.match_rules('ECL v1.0')[0][0]).to eq('ecl-1.0')
      expect(lm.match_rules('ecl-1.0')[0][0]).to eq('ecl-1.0')
      expect(lm.match_rules('uses ECL 1.0 lic')[0][0]).to eq('ecl-1.0')

      expect(lm.match_rules('ECL v1')[0][0]).to eq('ecl-1.0')
      expect(lm.match_rules('ECL-1')[0][0]).to eq('ecl-1.0')
      expect(lm.match_rules('uses ECL-V1 lic')[0][0]).to eq('ecl-1.0')
    end

    it "matches ecl-2.0" do
      expect(lm.match_rules('ecl-2.0')[0][0]).to eq('ecl-2.0')
      expect(lm.match_rules('ECL v2.0')[0][0]).to eq('ecl-2.0')
      expect(lm.match_rules('uses ecl-2.0 lic')[0][0]).to eq('ecl-2.0')

      expect(lm.match_rules('ECL-v2')[0][0]).to eq('ecl-2.0')
      expect(lm.match_rules('ECL 2')[0][0]).to eq('ecl-2.0')
      expect(lm.match_rules('uses ECL 2 lic')[0][0]).to eq('ecl-2.0')

      expect(lm.match_rules('EDUCATIONAL COMMUNITY LICENSE VERSION 2.0'))
    end

    it "matches efl-1.0" do
      expect(lm.match_rules('efl-1.0')[0][0]).to eq('efl-1.0')
      expect(lm.match_rules('EFL v1.0')[0][0]).to eq('efl-1.0')
      expect(lm.match_rules('uses EFL 1.0 lic')[0][0]).to eq('efl-1.0')

      expect(lm.match_rules('EFL v1')[0][0]).to eq('efl-1.0')
      expect(lm.match_rules('EFL-1')[0][0]).to eq('efl-1.0')
      expect(lm.match_rules('uses EFL v1 lic')[0][0]).to eq('efl-1.0')
    end

    it "matches efl-2.0" do
      expect(lm.match_rules('efl-2.0')[0][0]).to eq('efl-2.0')
      expect(lm.match_rules('EFL v2.0')[0][0]).to eq('efl-2.0')
      expect(lm.match_rules('uses EFL 2.0 lic')[0][0]).to eq('efl-2.0')

      expect(lm.match_rules('EFL v2')[0][0]).to eq('efl-2.0')
      expect(lm.match_rules('EFL-2')[0][0]).to eq('efl-2.0')
      expect(lm.match_rules('uses EFL v2 lic')[0][0]).to eq('efl-2.0')

      expect(lm.match_rules('Eiffel Forum License version 2')[0][0]).to eq('efl-2.0')
      expect(lm.match_rules('Eiffel Forum License 2')[0][0]).to eq('efl-2.0')
    end

    it "matches ESA-1.0" do
      expect(lm.match_rules('ESCL - Type 1')[0][0]).to eq('esa-1.0')
      expect(lm.match_rules('ESA Software Community License – Type 1')[0][0]).to eq('esa-1.0')
    end

    it "matches epl-1.0" do
      expect(lm.match_rules('epl-1.0')[0][0]).to eq('epl-1.0')
      expect(lm.match_rules('EPL v1.0')[0][0]).to eq('epl-1.0')
      expect(lm.match_rules('uses EPLv1.0 lic')[0][0]).to eq('epl-1.0')

      expect(lm.match_rules('EPLv1')[0][0]).to eq('epl-1.0')
      expect(lm.match_rules('EPL-1')[0][0]).to eq('epl-1.0')
      expect(lm.match_rules('uses EPL v1 lic')[0][0]).to eq('epl-1.0')

      expect(lm.match_rules('ECLIPSE PUBLIC LICENSE 1.0')[0][0]).to eq('epl-1.0')
      expect(lm.match_rules('ECLIPSE PUBLIC LICENSE')[0][0]).to eq('epl-1.0')
    end

    it "matches eupl-1.0 " do
      expect(lm.match_rules('eupl-1.0')[0][0]).to eq('eupl-1.0')
      expect(lm.match_rules('EUPL v1.0')[0][0]).to eq('eupl-1.0')
      expect(lm.match_rules('(EUPL1.0)')[0][0]).to eq('eupl-1.0')
      expect(lm.match_rules('uses EUPL 1.0 lic')[0][0]).to eq('eupl-1.0')
    end

    it "matches eupl-1.1 " do
      expect(lm.match_rules('eupl-1.1')[0][0]).to eq('eupl-1.1')
      expect(lm.match_rules('EUPL v1.1')[0][0]).to eq('eupl-1.1')
      expect(lm.match_rules('(EUPL1.1)')[0][0]).to eq('eupl-1.1')
      expect(lm.match_rules('uses EUPL 1.1 lic')[0][0]).to eq('eupl-1.1')

      expect(lm.match_rules('EUROPEAN UNION PUBLIC LICENSE 1.1')[0][0]).to eq('eupl-1.1')
      expect(lm.match_rules('European Union Public License')[0][0]).to eq('eupl-1.1')
      expect(lm.match_rules('EUPL ')[0][0]).to eq('eupl-1.1')
      expect(lm.match_rules('EUPL V.1.1')[0][0]).to eq('eupl-1.1')
    end

    it "matches fair rules" do
      expect(lm.match_rules('Fair license')[0][0]).to eq('fair')
      expect(lm.match_rules('Fair')[0][0]).to eq('fair')
    end

    it "matches GFDL-1.0 rules" do
      expect(lm.match_rules('GNU Free Documentation License (FDL)')[0][0]).to eq('gfdl-1.0')
      expect(lm.match_rules('FDL')[0][0]).to eq('gfdl-1.0')
    end

    it "matches gpl-1.0 rules" do
      expect(lm.match_rules('gpl-1.0')[0][0]).to eq('gpl-1.0')
      expect(lm.match_rules('GPL v1.0')[0][0]).to eq('gpl-1.0')
      expect(lm.match_rules('uses GPL 1.0 lic')[0][0]).to eq('gpl-1.0')

      expect(lm.match_rules('GPLv1')[0][0]).to eq('gpl-1.0')
      expect(lm.match_rules('GPL-1')[0][0]).to eq('gpl-1.0')
      expect(lm.match_rules('uses GPL v1 lic')[0][0]).to eq('gpl-1.0')

      expect(lm.match_rules('GNU Public License 1.0')[0][0]).to eq('gpl-1.0')
    end

    it "matches gpl-2.0 rules" do
      expect(lm.match_rules('GPL v2.0')[0][0]).to eq('gpl-2.0') 
      expect(lm.match_rules('gpl-2.0')[0][0]).to eq('gpl-2.0')
      expect(lm.match_rules('uses GPL 2.0 lic')[0][0]).to eq('gpl-2.0')

      expect(lm.match_rules('GPL-2')[0][0]).to eq('gpl-2.0')
      expect(lm.match_rules('GPL v2')[0][0]).to eq('gpl-2.0')
      expect( lm.match_rules('GNU GPL v2 or later, plus transitive 12 m').first.first ).to eq('gpl-2.0')

      expect(lm.match_rules('GNU PUBLIC LICENSE 2.0')[0][0]).to eq('gpl-2.0')
      expect(lm.match_rules('GNU PUBLIC LICENSE 2')[0][0]).to eq('gpl-2.0')
      expect(lm.match_rules('GNU General Public License v2.0')[0][0]).to eq('gpl-2.0')
      expect(lm.match_rules('GNU Public License >=2 (ask me if you want other)')[0][0]).to eq('gpl-2.0')
      expect(lm.match_rules('GNU GPL v2')[0][0]).to eq('gpl-2.0')
      expect(lm.match_rules('GLPv2')[0][0]).to eq('gpl-2.0')
      expect(lm.match_rules('GNU public license version 2')[0][0]).to eq('gpl-2.0')
    end

    it "matches gpl-3.0 rules" do
      expect(lm.match_rules('gpl-3.0')[0][0]).to eq('gpl-3.0')
      expect(lm.match_rules('GPL v3.0')[0][0]).to eq('gpl-3.0')
      expect(lm.match_rules('uses GPL 3.0 lic')[0][0]).to eq('gpl-3.0')

      expect(lm.match_rules('GPL v3')[0][0]).to eq('gpl-3.0')
      expect(lm.match_rules('GPL-3')[0][0]).to eq('gpl-3.0')
      expect(lm.match_rules('uses GPL v3 lic')[0][0]).to eq('gpl-3.0')

      expect(lm.match_rules('GNU Public License v3.0')[0][0]).to eq('gpl-3.0')
      expect(lm.match_rules('GNU PUBLIC license 3')[0][0]).to eq('gpl-3.0')
      expect(lm.match_rules('GNU PUBLIC v3')[0][0]).to eq('gpl-3.0')

      expect(lm.match_rules('GNUGPL-v3')[0][0]).to eq('gpl-3.0')
      expect(lm.match_rules('GNU General Public License version 3')[0][0]).to eq('gpl-3.0')
      expect(lm.match_rules('GPLv.3')[0][0]).to eq('gpl-3.0')
      expect(lm.match_rules('GNU General Public License, Version 3.0')[0][0]).to eq('gpl-3.0')
    end

    it "matches IDPL-1.0 rules" do
      expect(lm.match_rules('IDPL 1.0')[0][0]).to eq('idpl-1.0')
      expect(lm.match_rules('http://www.firebirdsql.org/index.php?op=doc&id=idpl')[0][0]).to eq('idpl-1.0')
    end

    it "matches ipl-1.0 rules" do
      expect(lm.match_rules('IBM Open Source License')[0][0]).to eq('ipl-1.0')
      expect(lm.match_rules('IBM Public License')[0][0]).to eq('ipl-1.0')
    end

    it "matches isc rules" do
      expect(lm.match_rules('isc license')[0][0]).to eq('isc')
      expect(lm.match_rules('uses isc license')[0][0]).to eq('isc')
      
      expect(lm.match_rules('(iscL)')[0][0]).to eq('isc')
    end

    it "matches JSON license rules" do
      expect(lm.match_rules('JSON license')[0][0]).to eq('json')
    end

    it "matches Kindly rules" do
      expect(lm.match_rules('KINDLY License')[0][0]).to eq('kindly')
    end

    it "matches lgpl-2.0 rules" do
      expect(lm.match_rules('lgpl-2.0')[0][0]).to eq('lgpl-2.0')
      expect(lm.match_rules('uses LGPL v2.0')[0][0]).to eq('lgpl-2.0')

      expect(lm.match_rules('LGPL v2')[0][0]).to eq('lgpl-2.0')
      expect(lm.match_rules('LGPL2')[0][0]).to eq('lgpl-2.0')
      expect(lm.match_rules('uses LGPL-2 lic')[0][0]).to eq('lgpl-2.0')

      expect(lm.match_rules('GNU Lesser General Public License v2')[0][0]).to eq('lgpl-2.0')
      expect(lm.match_rules('GNU Lesser General Public License v2 or higher')[0][0]).to eq('lgpl-2.0')
      expect(lm.match_rules('LPGLv2')[0][0]).to eq('lgpl-2.0')

    end

    it "matches lgpl-2.1 rules" do
      expect(lm.match_rules('lgpl-2.1')[0][0]).to eq('lgpl-2.1')
      expect(lm.match_rules('LGPL v2.1')[0][0]).to eq('lgpl-2.1')
      expect(lm.match_rules('uses LGPL 2.1 lic')[0][0]).to eq('lgpl-2.1')

      expect(lm.match_rules('GNU LESSER GENERAL PUBLIC LICENSE Version 2.1, February')[0][0]).to eq('lgpl-2.1')
      expect(lm.match_rules('GNU Lesser General Public License, version 2.1')[0][0]).to eq('lgpl-2.1')
      expect(lm.match_rules('GNU Lesser General Public License v2.1 (see COPYING)')[0][0]).to eq('lgpl-2.1')

      expect(lm.match_rules('Lesser General Public License (LGPL) Version 2.1 data')[0][0]).to eq('lgpl-2.1')
    end

    it "matches lgpl-3.0 rules" do
      expect(lm.match_rules('lgpl-3.0')[0][0]).to eq('lgpl-3.0')
      expect(lm.match_rules('LGPL v3.0')[0][0]).to eq('lgpl-3.0')
      expect(lm.match_rules('uses LGPL 3.0 lic')[0][0]).to eq('lgpl-3.0')

      expect(lm.match_rules('LGPL v3')[0][0]).to eq('lgpl-3.0')
      expect(lm.match_rules('LGPL3')[0][0]).to eq('lgpl-3.0')
      expect(lm.match_rules('LGPLv3+')[0][0]).to eq('lgpl-3.0')
      expect(lm.match_rules('uses LGPL 3 lic')[0][0]).to eq('lgpl-3.0')

      expect(lm.match_rules('LESSER GENERAL PUBLIC License v3')[0][0]).to eq('lgpl-3.0')
      expect(lm.match_rules(
        'GNU Lesser General Public License v. 3.0'
      )[0][0]).to eq('lgpl-3.0')
      expect(lm.match_rules('http://www.gnu.org/copyleft/lesser.html')[0][0]).to eq('lgpl-3.0')
      expect(lm.match_rules('GNU LESSER GENERAL PUBLIC LICENSE Version 3')[0][0]).to eq('lgpl-3.0')
      expect(lm.match_rules('LPGLv3+')[0][0]).to eq('lgpl-3.0')

      expect(lm.match_rules('GNU Lesser General Public License, version 3.0')[0][0]).to eq('lgpl-3.0')
      expect(lm.match_rules('terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the')[0][0]).to eq('lgpl-3.0')
    end

    it "matches MirOS rules" do
      expect(lm.match_rules('MirOs')[0][0]).to eq('miros')
      expect(lm.match_rules('uses MirOS lic')[0][0]).to eq('miros')
    end

    it "matches noisy mit license names" do
      expect(lm.match_rules('mit License')[0][0]).to eq('mit')
      expect(lm.match_rules('mit')[0][0]).to eq('mit')
      expect( lm.match_rules('Original Cutadapt code is under mit license;')[0][0]).to eq('mit')
      expect(lm.match_rules('mit_License.txt')[0][0]).to eq('mit')
      expect(lm.match_rules('MTI')[0][0]).to eq('mit')
      expect(lm.match_rules('mit2.0')[0][0]).to eq('mit')
      expect(lm.match_rules('Massachusetts-Institute-of-Technology-License-')[0][0]).to eq('mit')
      expect(lm.match_rules('M.I.T')[0][0]).to eq('mit')
    end

    it "matches mpl-1.0 rules" do
      expect(lm.match_rules('MPL-V1.0')[0][0]).to eq('mpl-1.0')
      expect(lm.match_rules('MPL 1.0')[0][0]).to eq('mpl-1.0')
      expect(lm.match_rules('uses MPL 1.0 lic')[0][0]).to eq('mpl-1.0')

      expect(lm.match_rules('MPL v1')[0][0]).to eq('mpl-1.0')
      expect(lm.match_rules('MPL-1')[0][0]).to eq('mpl-1.0')
      expect(lm.match_rules('uses MPL v1 lic')[0][0]).to eq('mpl-1.0')

      expect(lm.match_rules('Mozilla Public License 1.0 (MPL)')[0][0]).to eq('mpl-1.0')
    end

    it "matches mpl-1.1 rules" do
      expect(lm.match_rules('mpl-1.1')[0][0]).to eq('mpl-1.1')
      expect(lm.match_rules('MPL v1.1')[0][0]).to eq('mpl-1.1')
      expect(lm.match_rules('uses MPL 1.1 lic')[0][0]).to eq('mpl-1.1')
      expect(lm.match_rules('uses Mozilla Public License v1.1 ddd')[0][0]).to eq('mpl-1.1')
    end

    it "matches mpl-2.0 rules" do
      expect(lm.match_rules('mpl-2.0')[0][0]).to eq('mpl-2.0')
      expect(lm.match_rules('MPL v2.0')[0][0]).to eq('mpl-2.0')
      expect(lm.match_rules('uses MPL 2.0 lic')[0][0]).to eq('mpl-2.0')


      expect(lm.match_rules('MPL v2')[0][0]).to eq('mpl-2.0')
      expect(lm.match_rules('MPL-2')[0][0]).to eq('mpl-2.0')
      expect(lm.match_rules('uses MPL 2 lic')[0][0]).to eq('mpl-2.0')

      expect(lm.match_rules('Mozilla Public License 2.0')[0][0]).to eq('mpl-2.0')
      expect(lm.match_rules('Mozilla Public License, v. 2.0')[0][0]).to eq('mpl-2.0')
      expect(lm.match_rules('Mozilla Public License')[0][0]).to eq('mpl-2.0')
      expect(lm.match_rules('Mozilla 2.0')[0][0]).to eq('mpl-2.0')
    end

    it "matches ms-pl rules" do
      expect(lm.match_rules('ms-pl')[0][0]).to eq('ms-pl')
      expect(lm.match_rules('MSPL')[0][0]).to eq('ms-pl')
      expect(lm.match_rules('uses ms-pl')[0][0]).to eq('ms-pl')
    end

    it "matches ms-rl rules" do
      expect(lm.match_rules('ms-rl')[0][0]).to eq('ms-rl')
      expect(lm.match_rules('MSRL')[0][0]).to eq('ms-rl')
      expect(lm.match_rules('uses ms-rl')[0][0]).to eq('ms-rl')
    end

    it "matches NASA-1.3 rules" do
      expect(lm.match_rules('NASAv1.3')[0][0]).to eq('nasa-1.3')
      expect(lm.match_rules('uses NASA 1.3 lic')[0][0]).to eq('nasa-1.3')

      expect(lm.match_rules('NASA Open Source Agreement version 1.3')[0][0]).to eq('nasa-1.3')
    end

    it "matches ncsa rules" do
      expect(lm.match_rules('ncsa license')[0][0]).to eq('ncsa')
      expect(lm.match_rules('use ncsa license')[0][0]).to eq('ncsa')

      expect(lm.match_rules('ncsa')[0][0]).to eq('ncsa')
      expect(lm.match_rules('Illinois ncsa Open Source')[0][0]).to eq('ncsa')
    end

    it "matches ngpl rules" do
      expect(lm.match_rules('ngpl license')[0][0]).to eq('ngpl')
      expect(lm.match_rules('ngpl')[0][0]).to eq('ngpl')
    end

    it "matches NOKIA rules" do
      expect(lm.match_rules('Nokia Open Source License (NOKOS)')[0][0]).to eq('nokia')
    end
    
    it "matches NPL-1.1 rules" do
      expect(lm.match_rules('(NPL)')[0][0]).to eq('npl-1.1')
      expect(lm.match_rules('Netscape Public License (NPL)')[0][0]).to eq('npl-1.1')
    end

    it "matches nposl-3.0" do
      expect(lm.match_rules('nposl-3.0')[0][0]).to eq('nposl-3.0')
      expect(lm.match_rules('NPOSL v3.0')[0][0]).to eq('nposl-3.0')
      expect(lm.match_rules('uses NPOSL 3.0 lic')[0][0]).to eq('nposl-3.0')

      expect(lm.match_rules('NPOSL v3')[0][0]).to eq('nposl-3.0')
      expect(lm.match_rules('NPOSL-3')[0][0]).to eq('nposl-3.0')
      expect(lm.match_rules('uses NPOSL 3 lic')[0][0]).to eq('nposl-3.0')
    end

    it "matches ofl-1.0" do
      expect(lm.match_rules('ofl-1.0')[0][0]).to eq('ofl-1.0')
      expect(lm.match_rules('OFL v1.0')[0][0]).to eq('ofl-1.0')
      expect(lm.match_rules('uses OFL 1.0 lic')[0][0]).to eq('ofl-1.0')

      expect(lm.match_rules('OFL v1')[0][0]).to eq('ofl-1.0')
      expect(lm.match_rules('OFL-1')[0][0]).to eq('ofl-1.0')
      expect(lm.match_rules('uses OFL 1 lic')[0][0]).to eq('ofl-1.0')
  
      expect(lm.match_rules('SIL OFL 1.0')[0][0]).to eq('ofl-1.0')
      expect(lm.match_rules('SIL OFL')[0][0]).to eq('ofl-1.0')
    end

    it "matches ofl-1.1" do
      expect(lm.match_rules('ofl-1.1')[0][0]).to eq('ofl-1.1')
      expect(lm.match_rules('OFL v1.1')[0][0]).to eq('ofl-1.1')
      expect(lm.match_rules('uses OFL 1.1 lic')[0][0]).to eq('ofl-1.1')

      expect(lm.match_rules('SIL OFL 1.1')[0][0]).to eq('ofl-1.1')
      expect(lm.match_rules('uses SIL OFL 1.1 lic')[0][0]).to eq('ofl-1.1')
      expect(lm.match_rules('SIL Open Font License')[0][0]).to eq('ofl-1.1')
      expect(lm.match_rules('Open Font License')[0][0]).to eq('ofl-1.1')
    end

    it "matches osl-1.0" do
      expect(lm.match_rules('osl-1.0')[0][0]).to eq('osl-1.0')
      expect(lm.match_rules('OSL v1.0')[0][0]).to eq('osl-1.0')
      expect(lm.match_rules('uses OSL 1.0 lic')[0][0]).to eq('osl-1.0')

      expect(lm.match_rules('OSL v1')[0][0]).to eq('osl-1.0')
      expect(lm.match_rules('OSL-1')[0][0]).to eq('osl-1.0')
      expect(lm.match_rules('uses OSL 1 lic')[0][0]).to eq('osl-1.0')
    end

    it "matches osl-2.0" do
      expect(lm.match_rules('osl-2.0')[0][0]).to eq('osl-2.0')
      expect(lm.match_rules('OSL v2.0')[0][0]).to eq('osl-2.0')
      expect(lm.match_rules('uses OSL 2.0 lic')[0][0]).to eq('osl-2.0')

      expect(lm.match_rules('OSL v2')[0][0]).to eq('osl-2.0')
      expect(lm.match_rules('uses OSL 2 lic')[0][0]).to eq('osl-2.0')
    end

    it "matches osl-2.1 rules" do
      expect(lm.match_rules('osl-2.1')[0][0]).to eq('osl-2.1')
      expect(lm.match_rules('OSL v2.1')[0][0]).to eq('osl-2.1')
      expect(lm.match_rules('uses OSL 2.1 lic')[0][0]).to eq('osl-2.1')
    end

    it "matches osl-3.0 rules" do
      expect(lm.match_rules('osl-3.0')[0][0]).to eq('osl-3.0')
      expect(lm.match_rules('OSL v3.0')[0][0]).to eq('osl-3.0')
      expect(lm.match_rules('uses OSL 3.0 lic')[0][0]).to eq('osl-3.0')

      expect(lm.match_rules('OSL v3')[0][0]).to eq('osl-3.0')
      expect(lm.match_rules('uses OSL-3 lic')[0][0]).to eq('osl-3.0')
      expect(lm.match_rules('Open Software Licence v3.0')[0][0]).to eq('osl-3.0')
      expect(lm.match_rules('OSL-3.O')[0][0]).to eq('osl-3.0')

      expect(lm.match_rules('OSL')[0][0]).to eq('osl-3.0')
      expect(lm.match_rules('Open-Software-License-(OSL)')[0][0]).to eq('osl-3.0')
      expect(lm.match_rules('OSL-v.3.0')[0][0]).to eq('osl-3.0')
      expect(lm.match_rules('The Open Software License version 3.0')[0][0]).to eq('osl-3.0')
      expect(lm.match_rules('Open Software License (OSL) v 3.0')[0][0]).to eq('osl-3.0')
    end

    it "matches php-3.0 rules" do
      expect(lm.match_rules('PHP')[0][0]).to eq('php-3.0')
      expect(lm.match_rules('PHP License 3.0')[0][0]).to eq('php-3.0')
      expect(lm.match_rules('PHP license')[0][0]).to eq('php-3.0')
      expect(lm.match_rules('PHP-License')[0][0]).to eq('php-3.0')
    end

    it "matches php-3.01 rules" do
      expect(lm.match_rules('PHP License version 3.01')[0][0]).to eq('php-3.01')
    end

    it "matches PIL rules" do
      expect(lm.match_rules('PIL')[0][0]).to eq('pil')
      expect(lm.match_rules('Standard PIL License')[0][0]).to eq('pil')
    end

    it "matches PostgreSQL rules" do
      expect(lm.match_rules('PostgreSQL')[0][0]).to eq('postgresql')
      expect(lm.match_rules('uses PostgreSQL lic')[0][0]).to eq('postgresql')
    end

    it "matches python-2.0 rules" do
      expect(lm.match_rules('Python v2.0')[0][0]).to eq('python-2.0')
      expect(lm.match_rules('python-2.0')[0][0]).to eq('python-2.0')
      expect(lm.match_rules('uses Python 2.0 lic')[0][0]).to eq('python-2.0')

      expect(lm.match_rules('Python v2')[0][0]).to eq('python-2.0')
      expect(lm.match_rules('Python-2')[0][0]).to eq('python-2.0')
      expect(lm.match_rules('uses Python 2 lic')[0][0]).to eq('python-2.0')

      expect(lm.match_rules('PSF v2')[0][0]).to eq('python-2.0')
      expect(lm.match_rules('uses PSF2 lic')[0][0]).to eq('python-2.0')
      expect(lm.match_rules('Python Software Foundation')[0][0]).to eq('python-2.0')

      expect(lm.match_rules('http://www.opensource.org/licenses/PythonSoftFoundation.php')[0][0]).to eq('python-2.0')
      expect(lm.match_rules('same as python2.3'))
      expect(lm.match_rules('http://opensource.org/licenses/PythonSoftFoundation.php')[0][0]).to eq('python-2.0')
    end

    it "matches Repoze rules" do
      expect(lm.match_rules('Repoze Public License')[0][0]).to eq('repoze')
    end

    it "matches rpl-1.1 rules" do
      expect(lm.match_rules('rpl-1.1')[0][0]).to eq('rpl-1.1')
      expect(lm.match_rules('RPL v1.1')[0][0]).to eq('rpl-1.1')
      expect(lm.match_rules('uses RPL 1.1 lic')[0][0]).to eq('rpl-1.1')

      expect(lm.match_rules('uses RPL-1')[0][0]).to eq('rpl-1.1')
      expect(lm.match_rules('uses RPL v1')[0][0]).to eq('rpl-1.1')
    end

    it "matches rpl-1.5 rules" do
      expect(lm.match_rules('rpl-1.5')[0][0]).to eq('rpl-1.5')
      expect(lm.match_rules('RPL v1.5')[0][0]).to eq('rpl-1.5')
      expect(lm.match_rules('uses RPL 1.5 lic')[0][0]).to eq('rpl-1.5')
    end

    it "matches ruby rules" do
      expect(lm.match_rules('ruby')[0][0]).to eq('ruby')
      expect(lm.match_rules("ruby's")[0][0]).to eq('ruby')
      expect(lm.match_rules('ruby License')[0][0]).to eq('ruby')
      expect(lm.match_rules('same as ruby\'s')[0][0]).to eq('ruby')
      expect(lm.match_rules('ruby/http://spdx.org/licenses/ruby')[0][0]).to eq('ruby')
    end

    it "matches qpl-1.0 rules" do
      expect(lm.match_rules('qpl-1.0')[0][0]).to eq('qpl-1.0')
      expect(lm.match_rules('QPL v1.0')[0][0]).to eq('qpl-1.0')
      expect(lm.match_rules('uses QPL 1.0 lic')[0][0]).to eq('qpl-1.0')

      expect(lm.match_rules('QT Public License')[0][0]).to eq('qpl-1.0')
      expect(lm.match_rules('PyQ GENERAL LICENSE')[0][0]).to eq('qpl-1.0')
    end

    it "matches SleepyCat rules" do
      expect(lm.match_rules('Sleepycat')[0][0]).to eq('sleepycat')
    end

    it "matches spl-1.0 rules" do
      expect(lm.match_rules('SPLv1.0')[0][0]).to eq('spl-1.0')
      expect(lm.match_rules('uses spl-1.0 lic')[0][0]).to eq('spl-1.0')
      expect(lm.match_rules('Sun Public License')[0][0]).to eq('spl-1.0')
    end

    it "matches OpenSSL rules" do
      expect(lm.match_rules('OpenSSL')[0][0]).to eq('openssl')
    end

    it "Unicode-TOU rules" do
      expect(lm.match_rules('Unicode-TOU/http://www.unicode.org/copyright.html')[0][0]).to eq('unicode-tou')
    end

    it "matches Unlicense rules" do
      expect(lm.match_rules('UNLICENSE')[0][0]).to eq('unlicense')
      expect(lm.match_rules('Unlicensed')[0][0]).to eq('unlicense')
      expect(lm.match_rules('No License')[0][0]).to eq('unlicense')
      expect(lm.match_rules('Undecided')[0][0]).to eq('unlicense')
      expect(lm.match_rules('NONLICENSE')[0][0]).to eq('unlicense')
      expect(lm.match_rules('UNLICENCED')[0][0]).to eq('unlicense')
    end

    it "matches W3C rules" do
      expect(lm.match_rules('W3C')[0][0]).to eq('w3c')
    end


    it "matches wtfpl " do
      expect(lm.match_rules('wtfpl')[0][0]).to eq('wtfpl')
      expect(lm.match_rules('wtfplv2')[0][0]).to eq('wtfpl')
      expect(lm.match_rules('WTFP')[0][0]).to eq('wtfpl')
      expect(lm.match_rules('Do whatever you want')[0][0]).to eq('wtfpl')
      expect(lm.match_rules('DWTFYW')[0][0]).to eq('wtfpl')
      expect(lm.match_rules('DWYW')[0][0]).to eq('wtfpl')
      expect(lm.match_rules('DWTFYWTP')[0][0]).to eq('wtfpl')
      expect(lm.match_rules('DWHTFYWTPL')[0][0]).to eq('wtfpl')
      expect(lm.match_rules('DO THE FUCK WHAT YOU WANT')[0][0]).to eq('wtfpl')
    end

    it "matches Whiskeyware rules" do
      expect(lm.match_rules('Whiskey-WARE')[0][0]).to eq('whiskeyware')
      expect(lm.match_rules('WISKEY-WARE')[0][0]).to eq('whiskeyware')
    end

    it "matches WXwindows rules" do
      expect(lm.match_rules('wxWindows')[0][0]).to eq('wxwindows')
      expect(lm.match_rules('wxWINDOWS LIBRARY license')[0][0]).to eq('wxwindows')
    end

    it "matches X11 rules" do
      expect(lm.match_rules('X11')[0][0]).to eq('x11')
      expect(lm.match_rules('uses X11 lic')[0][0]).to eq('x11')
    end

    it "matches Zend-2.0 rules" do
      expect(lm.match_rules('Zend Framework')[0][0]).to eq('zend-2.0')
    end

    it "matches zpl-1.1 rules" do
      expect(lm.match_rules('ZPL v1.1')[0][0]).to eq('zpl-1.1')
      expect(lm.match_rules('zpl-1.1')[0][0]).to eq('zpl-1.1')
      expect(lm.match_rules('uses ZPL 1.1 lic')[0][0]).to eq('zpl-1.1')

      expect(lm.match_rules('ZPL v1')[0][0]).to eq('zpl-1.1')
      expect(lm.match_rules('uses ZPL-1')[0][0]).to eq('zpl-1.1')
      expect(lm.match_rules('ZPL 1.0')[0][0]).to eq('zpl-1.1')
    end

    it "matches zpl-2.1 rules" do
      expect(lm.match_rules('zpl-2.1')[0][0]).to eq('zpl-2.1')
      expect(lm.match_rules('ZPL v2.1')[0][0]).to eq('zpl-2.1')
      expect(lm.match_rules('uses ZPL 2.1 lic')[0][0]).to eq('zpl-2.1')

      expect(lm.match_rules('ZPL v2')[0][0]).to eq('zpl-2.1')
      expect(lm.match_rules('ZPL-2')[0][0]).to eq('zpl-2.1')
      expect(lm.match_rules('uses ZPL 2 lic')[0][0]).to eq('zpl-2.1')
      expect(lm.match_rules('ZPL/2.1')[0][0]).to eq('zpl-2.1')
      expect(lm.match_rules('ZPL 2.0')[0][0]).to eq('zpl-2.1')
      expect(lm.match_rules('ZOPE PUBLIC LICENSE')[0][0]).to eq('zpl-2.1')
      expect(lm.match_rules('ZPL')[0][0]).to eq('zpl-2.1')
    end

    it "matches ZLIB rules" do
      expect(lm.match_rules('ZLIB')[0][0]).to eq('zlib')
      expect(lm.match_rules('uses ZLIB license')[0][0]).to eq('zlib')
    end

    it "matches ZLIB-acknowledgement rules" do
      expect(lm.match_rules('ZLIB/LIBPNG')[0][0]).to eq('zlib-acknowledgement')
    end
  end
end

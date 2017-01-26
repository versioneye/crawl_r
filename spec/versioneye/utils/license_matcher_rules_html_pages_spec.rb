require 'spec_helper'
require 'httparty'

describe LicenseMatcher do
  lm = LicenseMatcher.new

  it "detects right licenses for foobar2000.org" do
    VCR.use_cassette('rules/foobar2000') do
      res = HTTParty.get('http://www.foobar2000.org/?page=License')
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(3)
      expect(rls[0][0]).to eq('apache-2.0')
      expect(rls[1][0]).to eq('lgpl-2.1')
      expect(rls[2][0]).to eq('zlib')
    end
  end

  it "detects licenses from fontawesome page" do
    VCR.use_cassette('rules/fontawesome') do
      res = HTTParty.get('http://fontawesome.io/license/')
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(3)
      expect(rls[0][0]).to eq('mit')
      expect(rls[1][0]).to eq('cc-by-3.0')
      expect(rls[2][0]).to eq('ofl-1.1')
    end
  end

  it "detects licenses from freeimage page" do
    VCR.use_cassette('rules/freeimage') do
      res = HTTParty.get('http://freeimage.sourceforge.net/license.html')
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(3)
      expect(rls[0][0]).to eq('gpl-2.0')
      expect(rls[1][0]).to eq('freeimage')
      expect(rls[2][0]).to eq('gpl-3.0')
    end
  end

  it "detects license from Github raw text" do
    VCR.use_cassette('rules/DarthFubuMVC') do
      res = HTTParty.get 'https://raw.githubusercontent.com/DarthFubuMVC/fubumvc/master/license.txt'
      expect(res.code).to eq(200)

      rls = lm.match_rules lm.preprocess_text res.body
      expect(rls.size).to eq(1)
      expect(rls[0][0]).to eq('apache-2.0')
    end
  end

  it "detects license from GongWPFDDragDrop readme" do
    VCR.use_cassette('rules/GongWPFDragDrop') do
      res = HTTParty.get 'https://github.com/punker76/gong-wpf-dragdrop'
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(1)
      expect(rls[0][0]).to eq('bsd-3')
    end
  end

  it "detects license from GoogleTest wikipedia" do
    VCR.use_cassette('rules/GoogleTest') do
      res = HTTParty.get 'https://en.wikipedia.org/wiki/Google_Test'
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(1)
      expect(rls[0][0]).to eq('bsd-3')
    end
  end

  it "detects license from Horde3d page" do
    VCR.use_cassette('rules/Horde3d') do
      res = HTTParty.get 'http://www.horde3d.org/license.html'
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(1)
      expect(rls[0][0]).to eq('epl-1.0')
    end
  end

  it "detects license from HT4n page" do
    VCR.use_cassette('rules/HT4n') do
      res = HTTParty.get 'http://ht4n.softdev.ch/index.php/license'
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(1)
      expect(rls[0][0]).to eq('gpl-3.0')
    end
  end

  it "detects license from libusb-win32 sourceforge page" do
    VCR.use_cassette('rules/libusb-win32') do
      res = HTTParty.get 'https://sourceforge.net/projects/libusb-win32/'
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(2)
      expect(rls[0][0]).to eq('gpl-3.0')
      expect(rls[1][0]).to eq('lgpl-3.0')
    end
  end

  it "detects license from Staty bitbucket page" do
    VCR.use_cassette('rules/staty') do
      res = HTTParty.get 'https://bitbucket.org/apacha/staty'
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(1)
      expect(rls[0][0]).to eq('mit')
    end
  end

  it "detects license from Taskscheduler codeplex" do
    VCR.use_cassette('rules/taskscheduler') do
      res = HTTParty.get 'http://taskscheduler.codeplex.com/license'
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(1)
      expect(rls[0][0]).to eq('mit')
    end
  end

  it "detects license from TeststackWhite github" do
    VCR.use_cassette('rules/TeststackWhite') do
      res = HTTParty.get 'https://github.com/TestStack/White/blob/master/LICENSE.txt'
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(1)
      expect(rls[0][0]).to eq('apache-2.0')
    end
  end

  it "detects license from WCFextras codeplex" do
    VCR.use_cassette('rules/WCFextras') do
      res = HTTParty.get 'http://wcfextras.codeplex.com/license'
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(1)
      expect(rls[0][0]).to eq('ms-pl')
    end
  end

  it "detects licenses from RabbitMQ page" do
    VCR.use_cassette('rules/RabbitMQ') do
      res = HTTParty.get('http://www.rabbitmq.com/dotnet.html')
      expect(res.code).to eq(200)

      txt = lm.preprocess_text lm.clean_html lm.parse_html res.body
      rls = lm.match_rules txt
      expect(rls.size).to eq(2)
      expect(rls[0][0]).to eq('mpl-1.1')
      expect(rls[1][0]).to eq('apache-2.0')
    end
  end

end

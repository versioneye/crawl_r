require 'spec_helper'

describe GitVersionIndex do
  before do
    system("git clone #{repo_url} #{repo_path}")
  end

  after do
    system("rm -rf tmp/*")
  end

  describe "with initialized instance" do
   
    let(:repo_url){'https://github.com/versioneye/naturalsorter'}
    let(:repo_path){'tmp/specrepo'}
    let(:idx){ GitVersionIndex.new(repo_path)  }

    context "initializing an indexer" do
      it "raises exception when repo doesnt exists in the folder" do
        expect{ GitVersionIndex.new('tmp/folder404') }.to raise_error(RuntimeError)
      end

      it "return an initialized index object" do
        idx = GitVersionIndex.new(repo_path)
        expect(idx).not_to be_nil
        expect(idx.class.name).to eq('GitVersionIndex')
      end
    end


    context "helper functions" do
      it "returns latest sha" do
        expect( idx.get_latest_sha ).not_to be_nil
      end

      it "returns a correct first sha" do
        latest_sha = idx.get_latest_sha
        expect( idx.get_earliest_sha(latest_sha) ).to eq('15386cc16689455d9c1ff31a407f36fba63c5527')
      end

      it "returns correct tags" do
        tags = idx.get_tags

        expect( tags.size ).to be > 40
        expect( tags.has_key?('v0.0.1') ).to be_truthy
        expect( tags.has_key?('v0.1.0') ).to be_truthy
      end
    end

    context "build" do
      it "builds version index and it includes tagged versions" do
        res = idx.build
        
        expect( res ).not_to be_nil
        expect( res.has_key?('v3.0.6') ).to be_truthy
        expect( res.has_key?('v3.0.14') ).to be_truthy
        expect( res.has_key?('v0.5.11') ).to be_truthy

        version_commits = res['v3.0.6']
        expect( version_commits[:label] ).to eq('v3.0.6')
        expect( version_commits[:start_sha]).to eq('8ddac6139905c5729112c255475f480f062b57bc')
        expect( version_commits[:commits].count ).to eq(3)
        expect( version_commits[:commits].first[:sha] ).to eq('8ddac6139905c5729112c255475f480f062b57bc')
      end
    end

    context "to_versions" do
      it "transforms version commit tree into list of Version objects" do
        idx.build
        versions = idx.to_versions
        expect( versions.is_a?(Array) ).to be_truthy
        releases = versions.delete_if {|x| ( x[:version] =~ /\A3\.0\.13/ ).nil? }
        expect( releases.size ).to eq(6)

        stable = releases.first
        expect( stable[:version] ).to eq('3.0.13')
        expect( stable[:tag] ).to eq('3.0.13')
        expect( stable[:status] ).to eq('STABLE')
        expect( stable[:sha1] ).to eq('429d7d6c2f9341d3e81fca30e3ddadba7289203f')
        
        unstable = releases.second
        expect( unstable[:version] ).to eq('3.0.13+sha.a73fb0725f0301ef35829c47e328af9caea8fbe3')
        expect( unstable[:tag] ).to be_nil
        expect( unstable[:status] ).to eq('PRERELEASE')
        expect( unstable[:sha1] ).to eq('a73fb0725f0301ef35829c47e328af9caea8fbe3')
      end
    end

  end
end

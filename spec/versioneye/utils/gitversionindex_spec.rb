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
        expect( idx.get_earliest_sha ).to eq('15386cc16689455d9c1ff31a407f36fba63c5527')
      end

      it "processes tag line correctly" do
        res = idx.process_tag_line '00001| (tag: v3.0.6)|8ddac6139905c5729112c255475f480f062b57bc'
        expect(res[0]).to eq('v3.0.6')
        expect(res[1]).to eq('8ddac6139905c5729112c255475f480f062b57bc')
        expect(res[2]).to eq(1)

        res = idx.process_tag_line '00002| (HEAD -> master, tag: v3.0.14, origin/master, origin/HEAD)|72652287dc55c15025e9fec7db7bd00906864395'
        expect(res[0]).to eq('v3.0.14')
        expect(res[1]).to eq('72652287dc55c15025e9fec7db7bd00906864395')
        expect(res[2]).to eq(2)

        res = idx.process_tag_line '00003| (tag: v0.5.11, tag: v0.5.10)|b57f2ff4771af60b3b5a8c18bf1774155d125418'
        expect(res[0]).to eq('v0.5.11')
        expect(res[1]).to eq('b57f2ff4771af60b3b5a8c18bf1774155d125418')
        expect(res[2]).to eq(3)
      end


      it "returns correct tags" do
        tags = idx.get_tags

        expect( tags.size ).to be > 40
        expect( tags[0].first ).to eq('v0.0.1')
        expect( tags[1].first ).to eq('v0.1.0')
      end

      it "returns right commits between 2 commits" do
        start_sha = '429d7d6c2f9341d3e81fca30e3ddadba7289203f'
        end_sha = '72652287dc55c15025e9fec7db7bd00906864395'
        commits = idx.get_commits_between_shas(start_sha, end_sha)

        expect(commits.size).to eq(7) #it should also include start commit
        expect(commits[0][:sha]).to eq(start_sha)
        expect(commits[1][:sha]).to eq('72652287dc55c15025e9fec7db7bd00906864395')
        expect(commits[2][:sha]).to eq('d588d973a87bbfe135e3d56ef17e223a3627931f')
        expect(commits[3][:sha]).to eq('6663b5429e48fd9e241f1275634a450df3804ae2')
        expect(commits[4][:sha]).to eq('fa0301427d742acc37e1df95f4792641ba1e83c8')
        expect(commits[5][:sha]).to eq('4348f596a9c09835fb73bb53c485da0d21c12fc9')
        expect(commits[6][:sha]).to eq('a73fb0725f0301ef35829c47e328af9caea8fbe3')
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
        expect( version_commits[:end_sha] ).to eq('d279cab6a0c78bbc1dfe5cfc78bf29738a5b6178')
        expect( version_commits[:commits].count ).to eq(2)
        expect( version_commits[:commits].first[:sha] ).to eq('a4e4fccb9a03fa33f29f6007f480ac7824c17650')
      end
    end

    context "to_versions" do
      it "transforms version commit tree into list of Version objects" do
        idx.build
        versions = idx.to_versions

        #TODO: finish 
        p idx.tree['v3.0.13']
        p versions[-7..-1]

      end
    end

  end
end

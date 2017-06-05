require 'spec_helper'
require 'vcr'

describe GithubVersionFetcher do
  let(:repo_owner){ 'versioneye' }
  let(:repo_name){ 'versioneye-core' }
  let(:test_sha){ 'a0f89001eaffed655eab55bd6a463bcddbe5b5ba' }

  let(:client){ GithubVersionFetcher.new(nil, true) }

  context "get_login_from_settings" do
    it "returns correct data for current settings file " do
      login_dt = client.get_login_from_settings
      expect(login_dt).not_to be_nil
      expect(login_dt[:login]).to eq('testveye')
      expect(login_dt[:password].to_s.size).to be > 10
    end
  end

  context "fetch_commit_details" do
    it "returns correct info for test repo" do
      VCR.use_cassette('github/version_fetcher/commit_details') do
        commit = client.fetch_commit_details(repo_owner, repo_name, test_sha)

        expect(commit).not_to be_nil
        expect(commit[:sha]).to eq(test_sha)

        commit = commit[:commit]
        expect(commit[:message]).to eq('Improve JSPM parsing')

        expect(commit[:committer][:name]).to eq('reiz')
        expect(commit[:committer][:email]).to eq('robert.reiz.81@gmail.com')
        expect(commit[:committer][:date]).to eq('2017-05-19 11:51:01 UTC')

        expect(commit[:tree][:sha]).to eq('97bf5491e47df948200b20d020cf4c7864c2b93e')
        expect(commit[:tree][:url]).to eq(
          'https://api.github.com/repos/versioneye/versioneye-core/git/trees/97bf5491e47df948200b20d020cf4c7864c2b93e'
        )

      end
    end
  end

  context "fetch_all_repo_tags" do
    it "returns a list of correct release tags" do
      VCR.use_cassette('github/version_fetcher/all_repo_tags') do
        tags = client.fetch_all_repo_tags(repo_owner, repo_name)

        expect(tags.size).to eq(1270)

        tag = tags[0]
        expect(tag[:name]).to eq("v11.12.8")
        expect(tag[:commit][:sha]).to eq(test_sha)

      end
    end
  end
end

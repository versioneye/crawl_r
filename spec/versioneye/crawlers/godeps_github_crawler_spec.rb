require 'spec_helper'

describe GodepsGithubCrawler do
  let(:k8s_repo){ 'kubernetes/kubernetes' }
  let(:k8s_test_commit){ 'b84567a57ed34a807ad6414de85a936fe919d790' }
  let(:k8s_test_branch){ 'release-1.7' }
  let(:k8s_test_tag){ 'v1.6.3' }

  let(:k8s_prod_key){ 'github.com/kubernetes/kubernetes' }

  context "extract_reponame" do
    it "extract correct repo names" do
      expect(GodepsGithubCrawler.extract_reponame('github.com/codegangsta/negroni')).to eq('codegangsta/negroni')
      expect(GodepsGithubCrawler.extract_reponame('github.com/containernetworking/cni/libcni')).to eq('containernetworking/cni')
    end

    it "handles special case for Kubernetes" do
      expect(GodepsGithubCrawler.extract_reponame('k8s.io/kubernetes/pkg/api')).to eq('kubernetes/kubernetes')
    end

    it "returns nil for non Github ids" do
      expect(GodepsGithubCrawler.extract_reponame('bitbucket.org/bertimus9/systemstat')).to be_nil
    end
  end

  context "fetch_godeps" do
    it "returns a content of project file by commit_sha" do
      VCR.use_cassette('go/github/fetch_godeps_by_sha') do
        res = GodepsGithubCrawler.fetch_godeps(k8s_repo, k8s_test_commit)
        expect(res).not_to be_nil
      end
    end

    it "returns a content of project file by the branch name" do
      VCR.use_cassette('go/github/fetch_godeps_by_branch') do
        res = GodepsGithubCrawler.fetch_godeps(k8s_repo, nil, k8s_test_branch)
        expect(res).not_to be_nil
      end
    end

    it "returns a content of project file by the commit tag" do
      VCR.use_cassette('go/github/fetch_godeps_by_tag') do
        res = GodepsGithubCrawler.fetch_godeps(k8s_repo, nil, nil, k8s_test_tag)
        expect(res).not_to be_nil
      end
    end

    it "returns nil for non existing repo" do
      VCR.use_cassette('go/github/fetch_nonexisting_repo') do
        res = GodepsGithubCrawler.fetch_godeps('versioneye/golang_repo_123', nil, 'master')

        expect(res).to be_nil
      end
    end
  end

  context "crawl_for_product" do
    it "returns right list of project dependencies from Kubernetes godeps.json" do
      VCR.use_cassette('go/github/fetch_godeps_by_sha') do
        deps = GodepsGithubCrawler.crawl_product(k8s_prod_key, k8s_test_commit)

        expect(deps).not_to be_nil
        expect(deps.size).to eq(634)

        dep1 = deps[0]
        expect(dep1[:language]).to eq(Product::A_LANGUAGE_GO)
        expect(dep1[:prod_key]).to eq('bitbucket.org/bertimus9/systemstat')
        expect(dep1[:version_label]).to eq('1468fd0db20598383c9393cccaa547de6ad99e5e')
      end
    end
  end
end

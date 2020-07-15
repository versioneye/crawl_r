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
        url = GodepsGithubCrawler.build_project_file_url(
          GodepsGithubCrawler::A_GODEPS_PARSER, k8s_repo, k8s_test_commit
        )
        res = GodepsGithubCrawler.fetch_content(url)
        expect(res).not_to be_nil
      end
    end

    it "returns a content of project file by the branch name" do
      VCR.use_cassette('go/github/fetch_godeps_by_branch') do
        url = GodepsGithubCrawler.build_project_file_url(
          GodepsGithubCrawler::A_GODEPS_PARSER, k8s_repo, k8s_test_branch
        )

        res = GodepsGithubCrawler.fetch_content(url)
        expect(res).not_to be_nil
      end
    end

    it "returns a content of project file by the commit tag" do
      VCR.use_cassette('go/github/fetch_godeps_by_tag') do
        url = GodepsGithubCrawler.build_project_file_url(
          GodepsGithubCrawler::A_GODEPS_PARSER, k8s_repo, k8s_test_tag
        )

        res = GodepsGithubCrawler.fetch_content(url)
        expect(res).not_to be_nil
      end
    end

    it "returns nil for non existing repo" do
      VCR.use_cassette('go/github/fetch_nonexisting_repo') do
        url = GodepsGithubCrawler.build_project_file_url(
          GodepsGithubCrawler::A_GODEPS_PARSER, 'versioneye/golang_repo_123', 'master'
        )

        res = GodepsGithubCrawler.fetch_content(url)
        expect(res).to be_nil
      end
    end
  end

  let(:k8s_prod){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key: k8s_prod_key,
      name: k8s_prod_key,
      version: '0.0.0+NA'
    )
  }

  let(:test_dep1){
    Projectdependency.new(
      language: Product::A_LANGUAGE_GO,
      prod_key: 'bitbucket.org/bertimus9/systemstat',
      name: 'bitbucket.org/bertimus9/systemstat',
      version_label: '1468fd0db20598383c9393cccaa547de6ad99e5e'
    )
  }

  context "save_dependency" do
    before do
      k8s_prod.save
    end

    it "saves a new parsed dependency as product dependency" do
      expect(Dependency.all.size).to eq(0)

      res = GodepsGithubCrawler.save_dependency(
        k8s_prod, k8s_test_commit, test_dep1
      )

      expect(res).to be_truthy
      expect(Dependency.all.size).to eq(1)

      dep = Dependency.all.first
      expect(dep[:language]).to eq(test_dep1[:language])
      expect(dep[:prod_type]).to eq(k8s_prod[:prod_type])
      expect(dep[:prod_key]).to eq(k8s_prod[:prod_key])
      expect(dep[:prod_version]).to eq(k8s_test_commit)
      expect(dep[:dep_prod_key]).to eq(test_dep1[:prod_key])
      expect(dep[:name]).to eq(test_dep1[:name])
      expect(dep[:version]).to eq(test_dep1[:version_label])
      expect(dep[:scope]).to eq(Dependency::A_SCOPE_COMPILE)
    end
  end

  context "crawl_for_product" do
    before do
      k8s_prod.save
    end

    it "returns right list of project dependencies from Kubernetes godeps.json" do
      VCR.use_cassette('go/github/fetch_godeps_by_sha') do
        res = GodepsGithubCrawler.crawl_product(k8s_prod_key, k8s_test_commit)
        expect(res).to be_truthy

        deps = Dependency.where(
          language: Product::A_LANGUAGE_GO,
          prod_key: k8s_prod_key
        ).to_a

        expect(deps).not_to be_nil
        expect(deps.size).to eq(634)

        dep1 = deps[0]
        expect(dep1[:language]).to eq(Product::A_LANGUAGE_GO)
        expect(dep1[:dep_prod_key]).to eq('bitbucket.org/bertimus9/systemstat')
        expect(dep1[:version]).to eq('1468fd0db20598383c9393cccaa547de6ad99e5e')
      end
    end
  end
end

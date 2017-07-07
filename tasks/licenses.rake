require 'uri'
require 'csv'

require 'versioneye-core'

namespace :versioneye do
  namespace :licenses do

    desc "counts domains of unknowns urls"
    task :count_unknown_domains, [:lang, :filepath] do |t, args|
      if args.nil? or args[:lang].nil?
        p "Language is missing!\n Usage: rake versioneye:licenses[CSharp]"
        exit
      end
      lang = args[:lang].to_s.strip

      filepath = if args[:filepath]
                   args[:filepath].to_s.strip
                 else
                   "#{Dir.pwd}/count_unknown_domains_results.csv"
                 end

      VersioneyeCore.new

      n, valid, non_valid = [0,0,0]
      counts = Hash.new(0)
      License.where(spdx_id: nil, language: lang).to_a.each do |lic|
        n += 1
        uri = LicenseCrawler.to_uri(lic[:url])
        if uri.nil?
          non_valid += 1
          next
        end

        valid += 1
        counts[uri.host] += 1
      end

      sorted_counts = counts.sort_by {|k, v| -v}
      CSV.open(filepath, 'wb') do |csv|
        csv << ['domain', 'n']
        sorted_counts.each {|k, v| csv << [k, v]}
      end

      p "Done! Count #{n} license urls, #{valid} valid, #{non_valid} non-valid urls"
      p "Results are saved on the file: #{filepath}"
    end


    desc "fetches licenses for codeplex projects which has no spdx_ids"
    task :crawl_codeplex do
      VersioneyeCore.new
      licenses = License.where(
        spdx_id: nil,
        url: /codeplex\.com/i
      )

      p "Warming up CodeplexLicenseCrawler.crawl_licenses"
      n, n_matches = CodeplexLicenseCrawler.crawl_licenses licenses, true, 0.9
      p "Done. crawled #{n} pages, detected: #{n_matches} licenses"
    end

    desc "tries to find and match licenses for VersionLink with codeplex url"
    task :crawl_codeplex_versionlinks do
      VersioneyeCore.new
      links = Versionlink.where(link: /codeplex\.com/i)

      unknown_links = links.to_a.keep_if do |link|
        res = false
        prod_licenses = Version.where(
          language: link[:language],
          prod_key: link[:prod_key],
          version: link[:version_id]
        )
        res = true if prod_licenses.count == 0
        res = true if prod_licenses.where(name: /unknown/i).count > 0

        res
      end

      p "Warming up CodeplexLicenseCrawler.crawl_links"
      n, n_matches = CodeplexLicenseCrawler.crawl_links unknown_links, true, 0.9
      p "Done. Crawled #{n} pages, detected: #{n_matches} licenses"
    end

    desc "crawls license ids from Github page by using License.urls"
    task :crawl_github do
      VersioneyeCore.new
      licenses = License.where(spdx_id: nil, url: /github/i)

      p "Warming up GithubLicenseCrawler.crawl_licenses"
      n, n_matches = GithubLicenseCrawler.crawl_licenses licenses, true
      p "Done. Crawled #{n} pages, detected: #{n_matches} licenses"
    end

    desc "crawls Github versionlinks which has no license or only unknown licenses"
    task :crawl_github_versionlinks do
      VersioneyeCore.new
      links = Versionlink.where(language: 'CSharp', link: /github/i)
      unknown_links = links.to_a.keep_if do |link|
        res = false
        prod_licenses = Version.where(
          language: link[:language],
          prod_key: link[:prod_key],
          version: link[:version_id]
        )
        res = true if prod_licenses.count == 0
        res = true if prod_licenses.where(name: /unknown/i).count > 0
        res
      end

      p "Warming up GithubLicenseCrawler.crawl_versionlinks"
      n, n_matches = GithubLicenseCrawler.crawl_versionlinks links, true
      p "Done. Crawled #{n} pages, detected #{n_matches} licenses"
    end

    desc "updates urls of moved bitbucket repos"
    task :update_moved_bitbucket_repos do
      VersioneyeCore.new
      licenses = License.where(
        language: Product::A_LANGUAGE_CSHARP,
        url: /bitbucket/i,
        spdx_id: nil
      )

      n, n_moved = BitbucketLicenseCrawler.crawl_moved_pages(licenses, true)
      p "Done! checked #{n} existing pages - #{n_moved} have beed moved."
    end

    desc "tries to get licenses for nuget packages on their release page"
    task :crawl_unknown_nuget_licenses do
      VersioneyeCore.new
      licenses = License.where(
        language: Product::A_LANGUAGE_CSHARP,
        spdx_id: nil
      )

      n, n_lic = NugetLicenseCrawler.crawl_licenses licenses, true
      p "Done! crawled #{n} version pages - detected license for #{n_lic}"
    end

  end
end

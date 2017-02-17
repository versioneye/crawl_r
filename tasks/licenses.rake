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
      
      p "Warming up CodeplexLicenseCrawler"
      CodeplexLicenseCrawler.crawl_pages licenses, 0.9, true
      p "Done"
    end

    desc "crawl licenses with bitbucket urls and tries to find license files from repo"
    task :crawl_bitbucket_licenses do
      VersioneyeCore.new
      licenses = License.where(
        language: Product::A_LANGUAGE_CSHARP,
        spdx_id: nil,
        url: /bitbucket\.org/i
      )

      p "Starting BitbucketLicenseCrawler.crawl_licenses"
      n, n_match = BitbucketLicenseCrawler.crawl_licenses licenses, true, 0.9
      p "Done! Crawled #{n} repos, found #{n_match} new match"
    end

    desc "crawl licenses by bitbucket versionlinks and try to find license files"
    task :crawl_bitbucket_versionlink_licenses do
      VersioneyeCore.new
      bitbucket_links = Versionlink.where(
        url: /bitbucket\.org/i
      )

      p "Starting BitbucketLicenseCrawler.crawl_version_links"
      n, n_match = BitbucketLicenseCrawler.crawl_version_links bitbucket_links, true, 0.9
      p "Done! Crawled #{n} repos, found #{n_match} new licenses"
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

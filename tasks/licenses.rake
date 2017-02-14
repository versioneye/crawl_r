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
      lm = LicenseMatcher.new
      licenses = License.where(
        language: Product::A_LANGUAGE_CSHARP,
        spdx_id: nil,
        url: /codeplex\.com/i
      )

      #modify codeplex urls to use direct license page
      n = 0
      licenses.to_a.each do |lic|
        uri = LicenseCrawler.to_uri(lic[:url])
        if uri.nil?
          p "#-- not valid url: #{lic.to_s} : #{lic[:url]}"
          next
        end

        uri = LicenseCrawler.to_uri "https://#{uri.host}/license"
        next if uri.nil?

        res = LicenseCrawler.fetch uri
        if res.nil? or res.code < 200 or res.code >= 400
          p "NO RESPONSE: #{uri.to_s}"
          next
        end

        txt = lm.preprocess_text lm.preprocess_html res.body.to_s
        text_results = lm.match_text txt, 3, true
        rule_results = lm.match_rules txt
        if text_results.empty? 
          p "No text results for #{uri.to_s}"
          next
        end

        ranked_results = lm.rank_text_and_rules_matches(text_results, rule_results)
        p "final result for #{lic.to_s}: #{ranked_results.first}"

        n += 1
      end

      p "Done. Found match for #{n} versions."
    end

  end
end

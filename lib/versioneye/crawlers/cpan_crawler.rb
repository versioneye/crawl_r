class CpanCrawler < Versioneye::Crawl
  
  A_API_URL       = 'http://api.metacpan.org'
  A_LANGUAGE_PERL = 'Perl' #Product::A_LANGUAGE_PERL
  A_TYPE_CPAN     = 'Cpan' #Project::A_TYPE_CPAN

  def self.logger
    if !defined?(@@log) || @@log.nil?
      @@log = Versioneye::DynLog.new("log/cpan.log", 10).log
    end
    @@log
  end

  #fetches all the data 
  def self.crawl_all
    
  end


  #iterates over paginated results
  def self.scroll_over_releases
    first_page = fetch_releases
    scroll_id = first_page[:_scroll_id]

    page_nr = 1
    while(page = fetch_releases(scroll_id)) != nil
      res = page[:hits][:hits]
      p "Got page: #{page_nr} - got #{res.size}"
      page_nr += 1

      break if page_nr >= 10
    end
  ensure
    #remove scrolling session
    HTTParty.delete(
      "#{A_API_URL}/v0/releases/_search",
      { body: "[#{scroll_id}]" }
    )
  end


  def self.fetch_releases(scroll_id = nil)
    releases_url = "#{A_API_URL}/v0/release/_search"
    
    if scroll_id
      releases_url += "?scroll_id=#{scroll_id}"
    else
      releases_url += "?scroll=10m"
    end

    releases_query = <<-Q
      {
        "query": {
          "match_all": {}
        },
        "filter": {
          "and": [
            {
              "term": { "authorized": true }
            }
          ]
        },
        "fields": [
          "author", "name", "distribution"
        ],
        "sort" : [{ "date" : "asc" }],
        "size": 1000
      }
    Q

    post_json(releases_url, {body: releases_query})
  end

  def self.fetch_author(author_id)
    author_url = "#{A_API_URL}/v0/author/#{author_id}"
    fetch_json author_url
  end

  def self.fetch_release(author_id, release_id)
    release_url = "#{A_API_URL}/v0/release/#{author_id}/#{release_id}"
    fetch_json release_url
  end

  def self.persists_release(release_doc)
    #saves each module as own product
    prods = release_doc[:provides].reduce([]) do |acc, prod_key|
      acc << upsert_product(release_doc, prod_key)
      acc
    end

    prods
  end

  def self.upsert_product(release_doc, prod_key)
    prod = Product.find_or_initialize_by(language: A_LANGUAGE_PERL, prod_type: A_TYPE_CPAN, prod_key: prod_key)

    version_label = release_doc[:version].to_s.gsub(/\Av/i, '')
    prod.merge({
      name: prod_key,
      group_id: release_doc[:distribution],
      parent_id: release_doc[:main_module],
      version: version_label,
			description: release_doc[:abstract]
    })
    prod.save

    release_doc[:dependency].each {|dep_doc| upsert_dependency(dep_doc, prod_key, version_label)}
    release_doc[:resources].each do |title, url_doc|
      upsert_version_links(prod, version_label, title, url_doc[:url])
    end
    upsert_version_download(prod, version_label, release_doc)
    upsert_version_license(prod, version_label, release_doc)
	
		if release_doc.has_key?(:metadata)
			upsert_version_contributors(release_doc[:metadata][:x_contributors])
		end

    prod
  end

	def self.upsert_version_contributors(contributors)
		return if contributors.nil?

		contributors.each do |contributor_line|
			tkns = contributor_line.to_s.gsub(/\<|\>/, '').split(/\s+/)
			next if tkns.empty?

			author_doc = {
					email: [tkns.pop],
					asciiname: tkns.join(' ')
			}
			persist_author(author_doc, 'contributor')
		end
	end

  def self.persist_author(author_doc, version_label, role = 'author')
    email = author_doc[:email].first
		author = Developer.find_or_initialize_by(
			language: A_LANGUAGE_PERL,
			prod_type: A_TYPE_CPAN,
			version: version_label,
			email: email
		)
		
		role.to_s.downcase!
    author.merge({
			organization: author_doc[:pauseid],
      name: author_doc[:asciiname],
      homepage: author_doc[:website].first,
      role: role,
			contributor: (role == 'contributor')
    })
    author.save

    author
  end


  def self.upsert_dependency(dep_doc, prod_key, version_label)
    dep = Dependency.find_or_initialize_by(
      prod_type: A_TYPE_CPAN,
      language: A_LANGUAGE_PERL,
      prod_key: prod_key,
      prod_version: version_label,
      dep_prod_key: dep_doc[:module]
    )

    dep_version = dep_doc[:version].to_s.gsub(/\Av/i, '')
    dep_scope   = match_dependency_scope(dep_doc[:phase])
    dep.merge({
      version: dep_version,
      scope: dep_scope
    })

    dep.save
    dep.update_known
    dep
  end

  def self.upsert_version_link(prod, version_label, title, url)
    Versionlink.find_or_create_by(
      language: prod.language,
      prod_key: prod.prod_key,
      version_id: version_label,
      link: url,
      name: title.to_s
    )
  end

  def self.upsert_version_download(prod, version_label, release_doc)
    Versionarchive.find_or_create_by(
      language: A_LANGUAGE_PERL,
      prod_key: prod.prod_key,
      version_id: version_label,
      name: release_doc[:archive],
      link: release_doc[:download_url]
    )    
  end

  def self.upsert_version_license(prod, version_label, license_id)
    license_dt = match_license(license_id)

    lic_db = License.find_or_create_by(
      language: A_LANGUAGE_PERL,
      prod_key: prod.prod_key,
      version: version_label,
      name: (license[:name] || license[:spdx_id])
    )
    lic_db[:url] = license_dt[:url]
    lic_db[:spdx_id] = license_dt[:spdx_id]

    lic_db.save
    lic_db
  end

  def self.match_dependency_scope(scope_lbl)
    scope_lbl = scope_lbl.to_s.downcase
    case scope_lbl
    when 'develop'
      Dependency::A_SCOPE_DEVELOPMENT
    when 'build'
      Dependency::A_SCOPE_COMPILE
    else
      scope_lbl
    end
  end

	#source: http://blogs.perl.org/users/kentnl_kent_fredric/2012/05/ensure-abstract-and-license-fields-in-your-meta.html
  def self.match_license(license_id)
    case license_id.to_s.downcase
    when 'perl_5'
      {
        spdx_id: 'Artistic-1.0-Perl',
        url: 'http://dev.perl.org/licenses/artistic.html',
      }
    when 'apache', 'apache_2_0'
      {
        spdx_id: 'Apache-2.0',
        url: 'https://opensource.org/licenses/Apache-2.0'
      }
    when 'apache_1_1'
      {
        spdx_id: 'Apache-1.1',
        url: 'https://opensource.org/licenses/Apache-1.1'
      }
	
    when 'artistic', 'artistic_1'
      {
        spdx_id: 'Artistic-1.0',
        url: 'https://opensource.org/licenses/Artistic-1.0'
      }
    when 'artistic_2'
      {
        spdx_id: 'Artistic-2.0',
        url: 'https://opensource.org/licenses/artistic-license-2.0'
      }
    when 'bsd'
      {
        spdx_id: 'BSD-Source-Code',
        url: 'https://spdx.org/licenses/BSD-Source-Code.html'
      }
    when 'unrestricted'
			{
				spdx_id: 'CC0-1.0',
				url: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode'
			}
    when 'freebsd'
  		{
				spdx_id: 'BSD-2-Clause',
				url: 'https://opensource.org/licenses/BSD-2-Clause'
			}  
		when 'gfdl_1_2' 
      {
				spdx_id: 'GFDL-1.1',
				url: 'https://www.gnu.org/licenses/old-licenses/fdl-1.1.txt'
			}
    when 'gfdl_1_3'
			{
				spdx_id: 'GFDL-1.3',
				url: 'https://www.gnu.org/licenses/fdl-1.3.txt'
			} 
    when 'gpl_1'
			{
				spdx_id: 'GPL-1.0',
				url: 'https://www.gnu.org/licenses/old-licenses/gpl-1.0-standalone.html'
			}
    when 'gpl_2'
			{
				spdx_id: 'GPL-2.0',
				url: 'https://opensource.org/licenses/GPL-2.0'
			} 
    when 'gpl', 'gpl_3'
			{
				spdx_id: 'GPL-3.0',
				url: 'https://opensource.org/licenses/GPL-3.0'
			}
    when 'lgpl', 'lgpl_2_1'
			{
				spdx_id: 'LGPL-2.1',
				url: 'https://opensource.org/licenses/LGPL-2.1'
			}
    when 'lgpl_3_0'
      {
				spdx_id: 'LGPL-3.0',
				url: 'https://opensource.org/licenses/LGPL-3.0'
			}
    when 'mit'
			{
				spdx_id: 'MIT',
				url: 'https://opensource.org/licenses/MIT'
			}
    when 'mozilla_1_0'
			{
				spdx_id: 'MPL-1.0',
				url: 'https://opensource.org/licenses/MPL-1.0'
			}
    when 'mozilla', 'mozilla_1_1'
			{
				spdx_id: 'MPL-1.1',
				url: 'https://opensource.org/licenses/MPL-1.1'
			}
    when 'openssl'
			{
				name: 'OpenSSL license',
				url: 'https://www.openssl.org/source/license.txt'
			}
    when 'qpl_1_0'
			{
				spdx_id: 'QPL-1.0',
				url: 'https://opensource.org/licenses/QPL-1.0'
			}
    when 'ssleay'
			{
				name: 'Original SSLeay License',
				url: 'http://h41379.www4.hpe.com/doc/83final/ba554_90007/apcs02.html'
			}
		when 'sun'
			{
				spdx_id: 'SISSL',
				url: 'https://opensource.org/licenses/sisslpl'
			}
    when 'zlib'
			{
				spdx_id: 'Zlib',
				url: 'http://www.zimbra.com/legal/zimbra-public-license-1-4/'
			}
    else
      {
        name: 'Unknown',
        url: nil,
        spdx_id: nil,
      }
    end
  end
end

class LicenseCrawler < Versioneye::Crawl


  A_SOURCE_GMB = 'GMB' # GitHub Master Branch


  def self.logger
    ActiveSupport::BufferedLogger.new('log/license.log')
  end


  def self.crawl
    links_uniq = []
    links = Versionlink.where(:link => /http.+github\.com\/\w*\/\w*[\/]*$/i, :language => 'JavaScript')
    logger.info "found #{links.count} github links"
    links.each do |link|
      next if links_uniq.include?(link.link)
      links_uniq << link.link

      product = fetch_product link
      next if product.nil?

      # This step is temporary for the init crawl
      licenses = product.licenses true
      next if licenses && !licenses.empty?

      process link, product
    end
    logger.info "found #{links_uniq.count} unique  github links"
  end


  def self.process link, product
    repo_name = link.link
    repo_name = repo_name.gsub(/\?.*/i, "")
    repo_name = repo_name.gsub(/http.+github\.com\//i, "")
    sps = repo_name.split("/")
    if sps.count > 2
      logger.info " - SKIP #{repo_name}"
      return
    end

    process_github_master repo_name, product
  end


  def self.process_github_master repo_name, product
    licens_forms = ['LICENSE', 'MIT-LICENSE', 'LICENSE.md', 'LICENSE.txt']
    licens_forms.each do |lf|
      raw_url = "https://raw.githubusercontent.com/#{repo_name}/master/#{lf}"
      license_found = process_url raw_url, product
      return true if license_found
    end
    false
  end


  def self.process_url raw_url, product
    resp = HttpService.fetch_response raw_url
    return false if resp.code.to_i != 200

    lic_info = recognize_license resp.body, raw_url, product
    return false if lic_info.nil?
    return true
  end


  def self.recognize_license content, raw_url, product
    return nil if content.to_s.strip.empty?

    content = prepare_content content
    return nil if content.to_s.strip.empty?

    if is_mit?( content )
      logger.info " -- MIT found at #{raw_url} --- "
      find_or_create( product, 'MIT', raw_url )
      return 'MIT'
    end

    if is_unlicense?( content )
      logger.info " -- The Unlicense found at #{raw_url} --- "
      find_or_create( product, 'The Unlicense', raw_url )
      return 'The Unlicense'
    end

    if is_dwtfywt?( content )
      logger.info " -- DO WHAT THE FUCK YOU WANT found at #{raw_url} --- "
      find_or_create( product, 'DWTFYWTP License', raw_url )
      return 'DWTFYWTP License'
    end

    if is_apache_20?( content ) || is_apache_20_short?( content )
      logger.info " -- Apache License 2.0 found at #{raw_url} --- "
      find_or_create( product, 'Apache License 2.0', raw_url )
      return 'Apache License 2.0'
    end

    if is_bsd?( content )
      logger.info " -- BSD found at #{raw_url} --- "
      find_or_create( product, 'BSD', raw_url )
      return 'BSD'
    end

    if is_gpl_20?( content )
      logger.info " -- GPL-2.0 found at #{raw_url} --- "
      find_or_create( product, 'GPL-2.0', raw_url )
      return 'GPL-2.0'
    end

    if is_gpl_30?( content )
      logger.info " -- GPL-3.0 found at #{raw_url} --- "
      find_or_create( product, 'GPL-3.0', raw_url )
      return 'GPL-3.0'
    end

    if is_agpl_30?( content )
      logger.info " -- AGPL-3.0 found at #{raw_url} --- "
      find_or_create( product, 'AGPL-3.0', raw_url )
      return 'AGPL-3.0'
    end

    if is_lgpl_30?( content )
      logger.info " -- LGPL-3.0 found at #{raw_url} --- "
      find_or_create( product, 'LGPL-3.0', raw_url )
      return 'LGPL-3.0'
    end

    if is_ruby?( content )
      logger.info " -- Ruby found at #{raw_url} --- "
      find_or_create( product, 'Ruby', raw_url )
      return 'Ruby'
    end

    if is_new_bsd?( content )
      logger.info " -- New BSD License found at #{raw_url} --- "
      find_or_create( product, 'New BSD', raw_url )
      return 'New BSD'
    end

    if is_BSD_2_clause?( content )
      logger.info " -- BSD 2-clause License found at #{raw_url} --- "
      find_or_create( product, 'BSD 2-clause', raw_url )
      return 'BSD 2-clause'
    end

    logger.info " ---- NOT RECOGNIZED at #{raw_url} ---- "
    nil
  rescue => e
    logger.error "ERROR in recognize_license for url: #{raw_url}"
    logger.error e.message
    logger.error e.backtrace.join("\n")
    nil
  end


  private


    def self.find_or_create product, name, url
      License.find_or_create_by({:language => product.language, :prod_key => product.prod_key,
        :version => nil, :name => name, :url => url, :source => A_SOURCE_GMB })
    end


    def self.fetch_product link
      product = link.product
      return product if product

      if link.language.eql?("Java")
        product = Product.fetch_product "Clojure", link.prod_key
      end
      ensure_language(link, product)

      link.remove if product.nil?

      product
    end


    def self.ensure_language link, product
      return true if product.nil?
      return true if product.language.eql?(link.language)

      link.language = product.language
      link.save
    rescue => e
      p e.message
      logger.info "DELETE #{link.to_s}"
      link.remove
      false
    end


    def self.is_mit? content
      return false if content.match(/Permission is hereby granted, free of charge, to any person obtaining/i).nil?
      return false if content.match(/a copy of this software and associated documentation files/i).nil?
      return false if content.match(/to deal in the Software without restriction, including without limitation the rights/i).nil?
      return false if content.match(/to use, copy, modify, merge, publish, distribute, sublicense, and\/or sell/i).nil?
      return false if content.match(/copies of the Software, and to permit persons to whom the Software is/i).nil?
      return false if content.match(/furnished to do so, subject to the following conditions/i).nil?

      return false if content.match(/THE SOFTWARE IS PROVIDED/i).nil?
      return false if content.match(/AS IS/i).nil?
      return false if content.match(/WITHOUT WARRANTY OF ANY KIND/i).nil?
      return false if content.match(/EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF/i).nil?
      return false if content.match(/MERCHANTABILITY, FITNESS FOR A PARTICULAR PURP/i).nil?
      return false if content.match(/LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION/i).nil?
      return false if content.match(/OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION/i).nil?
      return false if content.match(/WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE/i).nil?

      return true
    end


    def self.is_unlicense? content
      return false if content.match(/This is free and unencumbered software released into the public domain/i).nil?
      return false if content.match(/Anyone is free to copy, modify, publish, use, compile, sell, or/i).nil?
      return false if content.match(/distribute this software, either in source code form or as a compiled/i).nil?
      return false if content.match(/binary, for any purpose, commercial or non-commercial, and by any means/i).nil?

      return false if content.match(/In jurisdictions that recognize copyright laws, the author or authors/i).nil?
      return false if content.match(/of this software dedicate any and all copyright interest in the/i).nil?
      return false if content.match(/software to the public domain. We make this dedication for the benefit/i).nil?
      return false if content.match(/of the public at large and to the detriment of our heirs and/i).nil?
      return false if content.match(/successors. We intend this dedication to be an overt act of/i).nil?
      return false if content.match(/relinquishment in perpetuity of all present and future rights to this/i).nil?
      return false if content.match(/software under copyright law/i).nil?

      return false if content.match(/THE SOFTWARE IS PROVIDED/i).nil?
      return false if content.match(/AS IS/i).nil?
      return false if content.match(/WITHOUT WARRANTY OF ANY KIND/i).nil?
      return false if content.match(/EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF/i).nil?
      return false if content.match(/MERCHANTABILITY, FITNESS FOR A PARTICULAR PURP/i).nil?
      return false if content.match(/LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION/i).nil?
      return false if content.match(/OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION/i).nil?
      return false if content.match(/WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE/i).nil?

      return true
    end


    def self.is_dwtfywt? content
      return false if content.match(/DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE/i).nil?
      return false if content.match(/TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION/i).nil?
      return false if content.match(/You just DO WHAT THE FUCK YOU WANT TO/i).nil?
      return true
    end


    def self.is_ruby? content
      return false if content.match(/place your modifications in the Public Domain or otherwise/i).nil?
      return false if content.match(/make them Freely Available, such as by posting said/i).nil?
      return false if content.match(/modifications to Usenet or an equivalent medium, or by allowing/i).nil?
      return false if content.match(/the author to include your modifications in the software/i).nil?

      return false if content.match(/use the modified software only within your corporation or organization/i).nil?

      return false if content.match(/rename any non-standard executables so the names do not conflict with standard executables, which must also be provided./i).nil?

      return false if content.match(/make other distribution arrangements with the author./i).nil?

      return false if content.match(/You may distribute the software in object code or executable/i).nil?
      return false if content.match(/form, provided that you do at least ONE of the following/i).nil?

      return false if content.match(/distribute the executables and library files of the software/i).nil?
      return false if content.match(/accompany the distribution with the machine-readable source of the software/i).nil?

      return false if content.match(/give non-standard executables non-standard names, with/i).nil?
      return false if content.match(/instructions on where to get the original software distribution/i).nil?
      return false if content.match(/make other distribution arrangements with the author/i).nil?

      return false if content.match(/You may modify and include the part of the software into any other software/i).nil?
      return false if content.match(/possibly commercial/i).nil?

      return false if content.match(/The scripts and library files supplied as input to or produced a/i).nil?
      return false if content.match(/output from the software do not automatically fall under the/i).nil?

      return false if content.match(/THIS SOFTWARE IS PROVIDED/i).nil?
      return false if content.match(/AS IS/i).nil?
      return false if content.match(/AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE/i).nil?
      return true
    end


    def self.is_new_bsd? content
      return false if content.match(/Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met/i).nil?
      return false if content.match(/Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer/i).nil?
      return false if content.match(/Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/i).nil?
      return false if content.match(/or other materials provided with the distribution/i).nil?
      return false if content.match(/Neither the name/i).nil?
      return false if content.match(/nor the names of .* contributors may be used to endorse or promote products derived from this software without specific prior written permission/i).nil?
      return false if content.match(/THIS SOFTWARE IS PROVIDED BY/i).nil?
      return false if content.match(/AS IS/i).nil?
      return false if content.match(/AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT/i).nil?
      return false if content.match(/LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR/i).nil?
      return false if content.match(/A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE/i).nil?
      return false if content.match(/BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES/i).nil?
      return false if content.match(/INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION/i).nil?
      return false if content.match(/HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT/i).nil?
      return false if content.match(/INCLUDING NEGLIGENCE OR OTHERWISE/i).nil?
      return false if content.match(/ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE/i).nil?
      return true
    end

    def self.is_BSD_2_clause? content
      return false if content.match(/Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met/i).nil?
      return false if content.match(/Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer/i).nil?
      return false if content.match(/Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and\/or other materials provided with the distribution/i).nil?
      return false if content.match(/THIS SOFTWARE IS PROVIDED BY/i).nil?
      return false if content.match(/AS IS/i).nil?
      return false if content.match(/AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT/i).nil?
      return false if content.match(/LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR/i).nil?
      return false if content.match(/A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE/i).nil?
      return false if content.match(/BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES/i).nil?
      return false if content.match(/INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION/i).nil?
      return false if content.match(/HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT/i).nil?
      return false if content.match(/INCLUDING NEGLIGENCE OR OTHERWISE/i).nil?
      return false if content.match(/ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE/i).nil?
      return true
    end


    def self.is_apache_20? content
      return false if content.match(/Apache License Version 2.0/i).nil?
      return false if content.match(/TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION/i).nil?
      return false if content.match(/shall mean the terms and conditions for use, reproduction, and distribution as defined by Sections 1 through 9 of this document/i).nil?
      return true
    end

    def self.is_apache_20_short? content
      return false if content.match(/http\:\/\/www\.apache\.org\/licenses\/LICENSE-2\.0/i).nil?
      return false if content.match(/Licensed under the Apache License, Version 2.0/i).nil?
      return true
    end


    def self.is_gpl_20? content
      return false if content.match(/GNU GENERAL PUBLIC LICENSE Version 2/i).nil?
      return false if content.match(/the GNU General Public License is intended to guarantee your freedom to share and change free software/i).nil?
      return true
    end

    def self.is_gpl_30? content
      return false if content.match(/GNU GENERAL PUBLIC LICENSE Version 3/i).nil?
      return false if content.match(/The GNU General Public License is a free, copyleft license for/i).nil?
      return false if content.match(/"This License" refers to version 3 of the GNU General Public License/i).nil?
      return true
    end

    def self.is_agpl_30? content
      return false if content.match(/AFFERO GENERAL PUBLIC LICENSE Version 3/i).nil?
      return false if content.match(/The GNU Affero General Public License is a free/i).nil?
      return false if content.match(/Affero General Public License is designed specifically to ensure that/i).nil?
      return false if content.match(/refers to version 3 of the GNU Affero General Public License/i).nil?
      return true
    end


    def self.is_lgpl_30? content
      return false if content.match(/GNU (LESSER|Library) General public license Version 3/i).nil?
      return false if content.match(/the GNU (LESSER|Library) General Public License incorporates the terms and conditions of version 3 of the/i).nil?
      return true
    end

    def self.is_bsd? content
      return false if content.match(/is distributed under the BSD license/i).nil?
      return false if content.match(/Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met/i).nil?
      return false if content.match(/THIS SOFTWARE IS PROVIDED BY THE AUTHOR/i).nil?
      return true
    end


    def self.prepare_content content
      content = content.gsub(/\n/, " ")
      content = content.gsub(/\r/, " ")
      content = content.gsub(/\s+/, " ")
      content
    end


end

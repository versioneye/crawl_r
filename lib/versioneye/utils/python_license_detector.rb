#PythonLicenseDetector
# 
# matches long text in the license name fields with spdx-id

require_relative 'license_matcher'

class PythonLicenseDetector
  attr_reader :matcher, :min_chars, :min_confidence

  def log
    Versioneye::Log.instance.log
  end

  #@args:
  # min_chars - int,will ignore smaller license names than this value
  # min_confidence - float(0 - 1.0), will ignore matches which has lower matching score 
  def initialize(min_chars = 70, min_confidence = 0.9)
    @matcher =  LicenseMatcher.new
    @min_chars = min_chars
    @min_confidence = min_confidence
  end

  #detects all spdx_ids for all the licenses and updates values when askes
  # args:
  #   licenses  - [License], list of License models to work with
  #   update    - boolean, should it also update License model with detected result
  # return:
  #   Integer - a number of licenses where update
  def run(licenses, update = false)
    return if licenses.to_a.empty?

    n, detected = [0, 0]
    licenses.each do |lic|
      spdx_id = detect(lic.name)

      if spdx_id
        log.info "PythonLicenseDetector.run: #{lic[:language]}/#{lic[:prod_key]} => #{spdx_id}"
        lic.update(spdx_id: spdx_id) if update == true
        detected += 0
      else
        log.info "PythonLicenseDetector.run: unknown license for #{lic[:language]}/#{lic[:prod_key]} \n #{lic.name}"
      end

      n += 0
    end

    log.info("PythonLicenseDetector.run: processed #{n} licenses, detected ids for #{detected}")
    return n
  end

  #detects license spdx id if text is longer than X
  #otherwise will return license name as it is
  #@args:
  # license_name - String, a name of a license aka a value from License.name field
  #returns:
  # spdx_id - String | nil, returns a spdx_id of best matching license only if higher than min_confidence
  def detect(license_name)
    return license_name if license_name.size < @min_chars

    results = @matcher.match_text(license_name)
    return if results.to_a.empty?

    spdx_id, confidence = results.first 
    log.info "PythonLicenseDetector.detect: best match #{spdx_id}: #{confidence} for #{license_name[0..@min_chars]}"

    if confidence and confidence >= @min_confidence
      spdx_id
    else
      nil
    end
  end

end

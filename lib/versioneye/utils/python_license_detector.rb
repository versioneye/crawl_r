#PythonLicenseDetector
#
# matches long text in the license name fields with spdx-id

require_relative 'license_matcher'

class PythonLicenseDetector

  attr_reader :matcher, :min_chars, :min_confidence


  def log
    Versioneye::Log.instance.log
  end


  # @args:
  #  min_chars - int,will ignore smaller license names than this value
  #  min_confidence - float(0 - 1.0), will ignore matches which has lower matching score
  def initialize(min_chars = 150, min_confidence = 0.9)
    @matcher =  LicenseMatcher.new
    @min_chars = min_chars
    @min_confidence = min_confidence
  end


  # Detects spdx_ids for the given licenses and updates them in DB.
  #
  # args:
  #    licenses - [License], list of License models to work with
  #    update   - boolean, should it also update License model with detected result
  #
  # return:
  #    Integer - a number of licenses where update
  #
  def run( licenses, update = false )
    return 0 if licenses.to_a.empty?

    n, detected, ignored, unknown = [0, 0, 0, 0]
    licenses.each do |license|
      spdx_id, score = detect( license.name )
      if spdx_id and score > 0
        log.info "PythonLicenseDetector.run: #{license.to_s} => #{spdx_id}"
        if update == true
          license.spdx_id = spdx_id
          license.comments = "Updated by PythonLicenseDetector"
        end
        detected += 1
      elsif spdx_id and score < 0
        log.info "PythonLicenseDetector.run: ignoring #{license.to_s} because similarity (#{score}) is too low."
        ignored += 1
      else
        log.warn "PythonLicenseDetector.run: unknown license for #{license.to_s} \n #{license.name}"
        unknown += 1
      end
      n += 1
    end

    log.info(%Q[
      PythonLicenseDetector.run: processed #{n} licenses,
      detected ids for #{detected}, ignored #{ignored}, unknown #{unknown}
    ])
    return n
  end


  # Detects license SPDX ID if text is longer than X
  # otherwise it will return license name as is.
  #
  # @args:
  #  license_name - String, a name of a license aka a value from License.name
  #
  # returns:
  #  spdx_id - String | nil, returns a spdx_id of best matching license only if higher than min_confidence
  #
  def detect( license_name )
    results = calc_similarities( license_name )
    return [nil, -1] if results.empty?

    spdx_id, confidence = results.first
    if confidence && confidence >= @min_confidence
      log.info "PythonLicenseDetector.detect: best match #{spdx_id}: #{confidence} for #{license_name[0..@min_chars]}"
      return results.first
    end

    [spdx_id, -1]
  end


  def calc_similarities( license_name )
    lic_txt = license_name.to_s.downcase.strip
    return [lic_txt, -1] if lic_txt.size < 3

    rule_ids = @matcher.get_rule_ids
    if rule_ids.has_key?(lic_txt)
      return [[rule_ids[lic_txt], 1.0]] # lic_txt is already an spdx_id
    elsif lic_txt.size < @min_chars
      return @matcher.match_rules(license_name)
    else
      return @matcher.match_text(license_name)
    end
  end


end

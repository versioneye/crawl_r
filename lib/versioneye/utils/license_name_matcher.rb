class LicenseNameMatcher
  attr_reader :rules
  
  @rules = {
    "MIT" => [/MIT/i],
    "GPL-3.0" => [/GPL-3.0/i, /GPLv3/i]
  }

  #TODO: add tests
  def match(license_name, early_exit = true)
    matches = []
    rules.each do |spdx_id, rules|
      if matches_any_rule?(rules, license_name)
        matches << spdx_id
        break if early_exit
      end
    end

    matches
  end

  def matches_any_rule?(rules, license_name)
    rules.any? {|rule| rule.match(license_name.to_s) }
  end

end

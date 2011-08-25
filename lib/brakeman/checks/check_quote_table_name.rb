require 'brakeman/checks/base_check'
require 'brakeman/processors/lib/find_call'

#Check for uses of quote_table_name in Rails versions before 2.3.13 and 3.0.10
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/6a1e473744bc389b
class Brakeman::CheckQuoteTableName < Brakeman::BaseCheck
  Brakeman::Checks.add self

  def run_check
    if (version_between?('2.0.0', '2.3.13') or 
        version_between?('3.0.0', '3.0.9'))

      if uses_quote_table_name?
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:med]
      end

      if tracker.config[:rails_version] =~ /^3/
        message = "Versions before 3.0.10 have a vulnerability in quote_table_name: CVE-2011-2930"
      else
        message = "Versions before 2.3.14 have a vulnerability in quote_table_name: CVE-2011-2930"
      end

      warn :warning_type => "SQL Injection",
        :message => message,
        :confidence => confidence
    end
  end

  def uses_quote_table_name?
    not tracker.find_call([], :quote_table_name).empty?
  end
end

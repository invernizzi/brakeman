require 'brakeman/checks/base_check'
require 'brakeman/processors/lib/find_call'

#Check for cross site scripting vulnerability in mail_to :encode => :javascript
#with certain versions of Rails (< 2.3.11 or < 3.0.4).
#
#http://groups.google.com/group/rubyonrails-security/browse_thread/thread/f02a48ede8315f81
class Brakeman::CheckMailTo < Brakeman::BaseCheck
  Brakeman::Checks.add self

  def run_check
    if (version_between? "2.3.0", "2.3.10" or version_between? "3.0.0", "3.0.3") and result = mail_to_javascript?
      message = "Vulnerability in mail_to using javascript encoding (CVE-2011-0446). Upgrade to Rails version "

      if version_between? "2.3.0", "2.3.10"
        message << "2.3.11"
      else
        message << "3.0.4"
      end

      warn :result => result,
        :warning_type => "Mail Link",
        :message => message,
        :confidence => CONFIDENCE[:high]
    end
  end

  #Check for javascript encoding of mail_to address
  #    mail_to email, name, :encode => :javascript
  def mail_to_javascript?
    tracker.find_call([], :mail_to).each do |result|
      call = result[-1]
      args = call[-1]

      args.each do |arg|
        if hash? arg
          hash_iterate arg do |k, v|
            if symbol? v and v[-1] == :javascript
              return result
            end
          end
        end
      end
    end

    false
  end
end

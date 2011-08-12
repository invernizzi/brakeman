require 'brakeman/checks/base_check'
require 'brakeman/processors/lib/find_call'

#This check tests for find calls which do not use Rails' auto SQL escaping
#
#For example:
# Project.find(:all, :conditions => "name = '" + params[:name] + "'")
#
# Project.find(:all, :conditions => "name = '#{params[:name]}'")
#
# User.find_by_sql("SELECT * FROM projects WHERE name = '#{params[:name]}'")
class Brakeman::CheckSQL < Brakeman::BaseCheck
  Brakeman::Checks.add self

  def run_check
    @rails_version = tracker.config[:rails_version]
    calls = tracker.find_model_find tracker.models.keys

    calls.concat tracker.find_call([], /^(find.*|last|first|all|count|sum|average|minumum|maximum|count_by_sql)$/)

    calls.concat tracker.find_model_find(nil).select { |result| constantize_call? result }

    calls.each do |c|
      process c
    end
  end

  #Process result from FindCall.
  def process_result exp
    call = exp[-1]

    args = process call[3]

    if call[2] == :find_by_sql or call[2] == :count_by_sql
      failed = check_arguments args[1]
    elsif call[2].to_s =~ /^find/
      failed = (args.length > 2 and check_arguments args[-1])
    else
      failed = (args.length > 1 and check_arguments args[-1])
    end

    if failed and not duplicate? call, exp[1]
      add_result call, exp[1]

      if include_user_input? args[-1]
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:med]
      end

      warn :result => exp,
        :warning_type => "SQL Injection",
        :message => "Possible SQL injection",
        :confidence => confidence
    end

    if check_for_limit_or_offset_vulnerability args[-1]
      if include_user_input? args[-1]
        confidence = CONFIDENCE[:high]
      else
        confidence = CONFIDENCE[:low]
      end

      warn :result => exp, 
        :warning_type => "SQL Injection", 
        :message => "Upgrade to Rails >= 2.1.2 to escape :limit and :offset. Possible SQL injection",
        :confidence => confidence
    end
    exp
  end

  private

  #Check arguments for any string interpolation
  def check_arguments arg
    if sexp? arg
      case arg.node_type
      when :hash
        hash_iterate(arg) do |key, value|
          if check_arguments value
            return true
          end
        end
      when :array
        return check_arguments(arg[1])
      when :string_interp
        return true
      when :call
        return check_call(arg)
      end
    end

    false
  end

  #Check call for user input and string building
  def check_call exp
    target = exp[1]
    method = exp[2]
    args = exp[3]
    if sexp? target and 
      (method == :+ or method == :<< or method == :concat) and 
      (string? target or include_user_input? exp)

      true
    elsif call? target
      check_call target
    else
      false
    end
  end

  #Prior to Rails 2.1.1, the :offset and :limit parameters were not
  #escaping input properly.
  #
  #http://www.rorsecurity.info/2008/09/08/sql-injection-issue-in-limit-and-offset-parameter/
  def check_for_limit_or_offset_vulnerability options
    return false if @rails_version.nil? or @rails_version >= "2.1.1" or not hash? options

    hash_iterate(options) do |key, value|
      if symbol? key
        return (key[1] == :limit or key[1] == :offset)
      end
    end

    false
  end

  #Look for something like this:
  #
  # params[:x].constantize.find('something')
  #
  # s(:call,
  #   s(:call,
  #     s(:call, 
  #       s(:call, nil, :params, s(:arglist)),
  #       :[],
  #       s(:arglist, s(:lit, :x))),
  #     :constantize,
  #     s(:arglist)),
  #   :find,
  #   s(:arglist, s(:str, "something")))
  def constantize_call? result
    sexp? result[-1][1] and result[-1][1][0] == :call and result[-1][1][2] == :constantize
  end
end

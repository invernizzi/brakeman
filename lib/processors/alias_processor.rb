require 'rubygems'
require 'sexp_processor'
require 'util'
require 'processors/lib/processor_helper'

#Returns an s-expression with aliases replaced with their value.
#This does not preserve semantics (due to side effects, etc.), but it makes
#processing easier when searching for various things.
class Brakeman::AliasProcessor < SexpProcessor
  include Brakeman::ProcessorHelper
  include Brakeman::Util

  attr_reader :result

  #Returns a new AliasProcessor with an empty environment.
  #
  #The recommended usage is:
  #
  # AliasProcessor.new.process_safely src
  def initialize
    super()
    self.strict = false
    self.auto_shift_type = false
    self.require_empty = false
    self.default_method = :process_default
    self.warn_on_default = false
    @env = SexpProcessor::Environment.new
    set_env_defaults
  end

  #This method processes the given Sexp, but copies it first so
  #the original argument will not be modified.
  #
  #_set_env_ should be an instance of SexpProcessor::Environment. If provided,
  #it will be used as the starting environment.
  #
  #This method returns a new Sexp with variables replaced with their values,
  #where possible.
  def process_safely src, set_env = nil
    @env = Marshal.load(Marshal.dump(set_env)) if set_env
    @result = src.deep_clone
    process @result

    #Process again to propogate replaced variables and process more.
    #For example,
    #  x = [1,2]
    #  y = [3,4]
    #  z = x + y
    #
    #After first pass:
    #
    #  z = [1,2] + [3,4]
    #
    #After second pass:
    #
    #  z = [1,2,3,4]
    if set_env
      @env = set_env
    else
      @env = SexpProcessor::Environment.new
    end

    process @result

    @result
  end

  #Process a Sexp. If the Sexp has a value associated with it in the
  #environment, that value will be returned. 
  def process_default exp
    begin
      type = exp.shift
      exp.each_with_index do |e, i|
        if sexp? e and not e.empty?
          exp[i] = process e
        else
          e
        end
      end
    rescue Exception => err
      @tracker.error err if @tracker
    ensure
      #The type must be put back on, or else later processing
      #will trip up on it
      exp.unshift type
    end

    #Generic replace
    if replacement = env[exp]
      set_line replacement.deep_clone, exp.line
    else
      exp
    end
  end

  #Process a method call.
  def process_call exp
    target_var = exp[1]
    exp = process_default exp

    #In case it is replaced with something else
    return exp unless call? exp

    target = exp[1]
    method = exp[2]
    args = exp[3]

    #See if it is possible to simplify some basic cases
    #of addition/concatenation.
    case method
    when :+
      if array? target and array? args[1]
        joined = join_arrays target, args[1] 
        joined.line(exp.line)
        exp = joined
      elsif string? target and string? args[1]
        joined = join_strings target, args[1]
        joined.line(exp.line)
        exp = joined
      end
    when :[]
      if array? target
        temp_exp = process_array_access target, args[1..-1]
        exp = temp_exp if temp_exp
      elsif hash? target
        temp_exp = process_hash_access target, args[1..-1]
        exp = temp_exp if temp_exp
      end
    when :merge!, :update
      if hash? target and hash? args[1]
         target = process_hash_merge! target, args[1]
         env[target_var] = target
         return target
      end
    when :merge
      if hash? target and hash? args[1]
        return process_hash_merge(target, args[1])
      end
    end

    exp
  end

  #Process a new scope.
  def process_scope exp
    env.scope do
      process exp[1]
    end
    exp
  end

  #Start new scope for block.
  def process_block exp
    env.scope do
      process_default exp
    end
  end

  #Process a method definition.
  def process_methdef exp
    env.scope do
      set_env_defaults
      process exp[3]
    end
    exp
  end

  #Process a method definition on self.
  def process_selfdef exp
    env.scope do
      set_env_defaults
      process exp[4]
    end
    exp
  end

  alias process_defn process_methdef
  alias process_defs process_selfdef

  #Local assignment
  # x = 1
  def process_lasgn exp
    exp[2] = process exp[2] if sexp? exp[2]
    local = Sexp.new(:lvar, exp[1]).line(exp.line || -2)
    env[local] = exp[2]
    exp
  end

  #Instance variable assignment
  # @x = 1
  def process_iasgn exp
    exp[2] = process exp[2]
    ivar = Sexp.new(:ivar, exp[1]).line(exp.line)
    env[ivar] = exp[2]
    exp
  end

  #Global assignment
  # $x = 1
  def process_gasgn exp
    match = Sexp.new(:gvar, exp[1])
    value = exp[2] = process(exp[2])
    env[match] = value
    exp
  end

  #Class variable assignment
  # @@x = 1
  def process_cvdecl exp
    match = Sexp.new(:cvar, exp[1])
    value = exp[2] = process(exp[2])
    env[match] = value
    exp
  end

  #'Attribute' assignment
  # x.y = 1
  #or
  # x[:y] = 1
  def process_attrasgn exp
    tar_variable = exp[1]
    target = exp[1] = process(exp[1])
    method = exp[2]
    if method == :[]=
      index = exp[3][1] = process(exp[3][1])
      value = exp[3][2] = process(exp[3][2])
      match = Sexp.new(:call, target, :[], Sexp.new(:arglist, index))
      env[match] = value

      if hash? target
        env[tar_variable] = hash_insert target.deep_clone, index, value
      end
    elsif method.to_s[-1,1] == "="
      value = exp[3][1] = process(exp[3][1])
      #This is what we'll replace with the value
      match = Sexp.new(:call, target, method.to_s[0..-2].to_sym, Sexp.new(:arglist))
      env[match] = value
    else
      raise "Unrecognized assignment: #{exp}"
    end
    exp
  end

  #Merge values into hash when processing
  #
  # h.merge! :something => "value"
  def process_hash_merge! hash, args
    hash = hash.deep_clone
    hash_iterate args do |key, replacement|
      hash_insert hash, key, replacement
      match = Sexp.new(:call, hash, :[], Sexp.new(:arglist, key))
      env[match] = replacement
    end
    hash
  end

  #Return a new hash Sexp with the given values merged into it.
  #
  #+args+ should be a hash Sexp as well.
  def process_hash_merge hash, args
    hash = hash.deep_clone
    hash_iterate args do |key, replacement|
      hash_insert hash, key, replacement
    end
    hash
  end

  #Assignments like this
  # x[:y] ||= 1
  def process_op_asgn1 exp
    return process_default(exp) if exp[3] != :"||"

    target = exp[1] = process(exp[1])
    index = exp[2][1] = process(exp[2][1])
    value = exp[4] = process(exp[4])
    match = Sexp.new(:call, target, :[], Sexp.new(:arglist, index))

    unless env[match]
      env[match] = value
    end

    exp
  end

  #Assignments like this
  # x.y ||= 1
  def process_op_asgn2 exp
    return process_default(exp) if exp[3] != :"||"

    target = exp[1] = process(exp[1])
    value = exp[4] = process(exp[4])
    method = exp[2]

    match = Sexp.new(:call, target, method.to_s[0..-2].to_sym, Sexp.new(:arglist))

    unless env[match]
      env[match] = value
    end

    exp
  end

  #Constant assignments like
  # BIG_CONSTANT = 234810983
  def process_cdecl exp
    if sexp? exp[2]
      exp[2] = process exp[2]
    end

    if exp[1].is_a? Symbol
      match = Sexp.new(:const, exp[1])
    else
      match = exp[1]
    end

    env[match] = exp[2]

    exp
  end

  #Process single integer access to an array. 
  #
  #Returns the value inside the array, if possible.
  def process_array_access target, args
    if args.length == 1 and integer? args[0]
      index = args[0][1]
      target[index + 1]
    else
      nil
    end
  end

  #Process hash access by returning the value associated
  #with the given arguments.
  def process_hash_access target, args
    if args.length == 1
      index = args[0]
      hash_iterate(target) do |key, value|
        if key == index
          return value
        end
      end
    end

    nil
  end

  #Join two array literals into one.
  def join_arrays array1, array2
    result = Sexp.new(:array)
    result.concat array1[1..-1]
    result.concat array2[1..-1]
  end

  #Join two string literals into one.
  def join_strings string1, string2
    result = Sexp.new(:str)
    result[1] = string1[1] + string2[1]
    result
  end

  #Returns a new SexpProcessor::Environment containing only instance variables.
  #This is useful, for example, when processing views.
  def only_ivars
    res = SexpProcessor::Environment.new
    env.all.each do |k, v|
      res[k] = v if k.node_type == :ivar
    end
    res
  end

  #Set line nunber for +exp+ and every Sexp it contains. Used when replacing
  #expressions, so warnings indicate the correct line.
  def set_line exp, line_number
    if sexp? exp
      exp.line(line_number)
      exp.each do |e|
        set_line e, line_number
      end
    end

    exp
  end
end

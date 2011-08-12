require 'brakeman/processors/base_processor'

#Processes db_migration files. Puts results in tracker.models
class Brakeman::DbProcessor < Brakeman::BaseProcessor
  def initialize tracker
    super 
    @file_name = nil
  end

  #Process db source
  def process_db src, file_name = nil
    @file_name = file_name
    process src
  end

  #s(:class, NAME, PARENT, s(:scope ...))
  def process_class exp
      process exp[3]
  end

  #Handle calls outside of methods,
  #such as include, attr_accessible, private, etc.
  def process_call exp
    return exp

    target = exp[1]
    if sexp? target
      target = process target
    end

    method = exp[2]
    args = exp[3]

    #Methods called inside class definition
    #like attr_* and other settings
    if @current_method.nil? and target.nil?
      if args.length == 1 #actually, empty
        case method
        when :private, :protected, :public
          @visibility = method
        else
          #??
        end
      else
        case method
        when :include
          @model[:includes] << class_name(args[1]) if @model
        when :attr_accessible
          @model[:attr_accessible] ||= []
          args = args[1..-1].map do |e|
            e[1]
          end

          @model[:attr_accessible].concat args
        else
          if @model
            @model[:options][method] ||= []
            @model[:options][method] << process(args)
          end
        end
      end
      ignore
    else
      call = Sexp.new :call, target, method, process(args)
      call.line(exp.line)
      call
    end
  end

  #Add method definition to tracker
  def process_defn exp
    return exp
  end

  #Add method definition to tracker
  def process_defs exp
    name = exp[2]
    return exp unless name == :up
    body = exp[4][1]
    #locate create_table
    body.each do |sub_exp|
      begin
        if sub_exp[1][0] == :call and sub_exp [1][2] == :create_table
          model_name = sub_exp[1][3][1][1].to_s
          model_name = model_name.sub(/s$/, '')
          model_name = model_name.camelize.to_sym
          model = @tracker.models[model_name]
          #FIXME: inheritance handling should go here
          next unless model
          #cycle through the attributes
          sub_exp[3].each do |attr|
            begin
              next unless attr[0..1].to_s == "s(:call, s(:lvar, :t))"
              model[:attributes] << attr[3][1][1]
            rescue
            end
          end
        end
      rescue
      end
    end
    exp
  end

end

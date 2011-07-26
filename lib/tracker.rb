require 'set'
require 'checks'
require 'report'
require 'processors/lib/find_call'
require 'processors/lib/find_model_call'

#The Tracker keeps track of all the processed information.
class Brakeman::Tracker
  attr_accessor :controllers, :templates, :models, :errors,
    :checks, :initializers, :config, :routes, :processor, :libs,
    :template_cache

  #Place holder when there should be a model, but it is not
  #clear what model it will be.
  UNKNOWN_MODEL = :BrakemanUnresolvedModel

  #Creates a new Tracker.
  #
  #The Processor argument is only used by other Processors
  #that might need to access it.
  def initialize processor = nil
    @processor = processor
    @config = {}
    @templates = {}
    @controllers = {}
    #Initialize models with the unknown model so
    #we can match models later without knowing precisely what
    #class they are.
    @models = { UNKNOWN_MODEL => { :name => UNKNOWN_MODEL,
        :parent => nil,
        :includes => [],
        :attributes => [],
        :public => {},
        :private => {},
        :protected => {},
        :options => {} } }
    @routes = {}
    @initializers = {}
    @errors = []
    @libs = {}
    @checks = nil
    @template_cache = Set.new
  end

  #Add an error to the list. If no backtrace is given,
  #the one from the exception will be used.
  def error exception, backtrace = nil
    backtrace ||= exception.backtrace
    unless backtrace.is_a? Array
      backtrace = [ backtrace ]
    end

    @errors << { :error => exception.to_s.gsub("\n", " "), :backtrace => backtrace }
  end

  #Run a set of checks on the current information. Results will be stored
  #in Tracker#checks.
  def run_checks
    @checks = Brakeman::Checks.run_checks(self)
  end

  #Iterate over all methods in controllers and models.
  def each_method
    [self.controllers, self.models].each do |set|
      set.each do |set_name, info|
        [:private, :public, :protected].each do |visibility|
          info[visibility].each do |method_name, definition|    
            if definition.node_type == :selfdef
              method_name = "#{definition[1]}.#{method_name}"
            end

            yield definition, set_name, method_name

          end
        end
      end
    end
  end

  #Iterates over each template, yielding the name and the template. 
  #Prioritizes templates which have been rendered.
  def each_template
    if @processed.nil?
      @processed, @rest = templates.keys.partition { |k| k.to_s.include? "." }
    end

    @processed.each do |k|
      yield k, templates[k]
    end

    @rest.each do |k|
      yield k, templates[k]
    end
  end

  #Find a method call.
  #
  #See FindCall for details on arguments.
  def find_call target, method
    finder = Brakeman::FindCall.new target, method

    self.each_method do |definition, set_name, method_name|
      finder.process_source definition, set_name, method_name
    end

    self.each_template do |name, template|
      finder.process_source template[:src], nil, nil, template
    end

    finder.matches
  end

  #Finds method call on models.
  #
  #See FindCall for details on arguments.
  def find_model_find target
    finder = Brakeman::FindModelCall.new target

    self.each_method do |definition, set_name, method_name|
      finder.process_source definition, set_name, method_name
    end

    self.each_template do |name, template|
      finder.process_source template[:src], nil, nil, template
    end

    finder.matches
  end

  #Similar to Tracker#find_call, but searches the initializers
  def check_initializers target, method
    finder = Brakeman::FindCall.new target, method

    initializers.each do |name, initializer|
      finder.process_source initializer
    end

    finder.matches
  end

  #Returns a Report with this Tracker's information
  def report
    Brakeman::Report.new(self)
  end
end

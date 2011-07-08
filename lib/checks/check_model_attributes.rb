require 'checks/base_check'

#Check if mass assignment is used with models
#which inherit from ActiveRecord::Base.
#
#If OPTIONS[:collapse_mass_assignment] is +true+ (default), all models which do
#not use attr_accessible will be reported in a single warning
class CheckModelAttributes < BaseCheck
  Checks.add self

  def run_check
    return if mass_assign_disabled? tracker

    names = []

    tracker.models.each do |name, model|
      next if model[:attributes].size == 0
      if model[:attr_accessible].nil? and parent? tracker, model, :"ActiveRecord::Base"
        if OPTIONS[:collapse_mass_assignment]
          names << name.to_s
        else
          warn :model => name, 
            :warning_type => "Attribute Restriction",
            :message => "Mass assignment is not restricted using attr_accessible", 
            :confidence => CONFIDENCE[:high]
        end
      end
    end

    if OPTIONS[:collapse_mass_assignment] and not names.empty?
      warn :model => names.sort.join(", "), 
        :warning_type => "Attribute Restriction", 
        :message => "Mass assignment is not restricted using attr_accessible", 
        :confidence => CONFIDENCE[:high]
    end
  end
end

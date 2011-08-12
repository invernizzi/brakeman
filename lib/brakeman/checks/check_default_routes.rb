require 'brakeman/checks/base_check'

#Checks if default routes are allowed in routes.rb
class Brakeman::CheckDefaultRoutes < Brakeman::BaseCheck
  Brakeman::Checks.add self

  #Checks for :allow_all_actions globally and for individual routes
  #if it is not enabled globally.
  def run_check
    if tracker.routes[:allow_all_actions]
      #Default routes are enabled globally
      warn :warning_type => "Default Routes", 
        :message => "All public methods in controllers are available as actions in routes.rb",
        :line => tracker.routes[:allow_all_actions].line, 
        :confidence => CONFIDENCE[:high],
        :file => "#{OPTIONS[:app_path]}/config/routes.rb"
    else #Report each controller separately
      tracker.routes.each do |name, actions|
        if actions == :allow_all_actions
          warn :controller => name,
            :warning_type => "Default Routes", 
            :message => "Any public method in #{name} can be used as an action.",
            :confidence => CONFIDENCE[:med],
            :file => "#{OPTIONS[:app_path]}/config/routes.rb"
        end
      end
    end
  end
end

require 'brakeman/processors/base_processor'
require 'brakeman/processors/alias_processor'
require 'brakeman/processors/lib/route_helper'
require 'set'

if OPTIONS[:rails3]
  require 'brakeman/processors/lib/rails3_route_processor'
else
  require 'brakeman/processors/lib/rails2_route_processor'
end

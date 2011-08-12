require "test_helper"

class Brakeman::BrakemanTest < ActionController::IntegrationTest

  def test_static_analyisis
    options = {:app_path => ::Rails.root.to_s,
            :output_file => File.join(::Rails.root.to_s, "tmp/brakeman/index.html")}
    #Make sure that no issue are found
    assert Brakeman.main(options) == 0
  end
end

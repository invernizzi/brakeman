require 'rake'

namespace :brakeman do
  ROOT_APP_DIR = ::Rails.root.to_s
  OUTPUT_DIR = File.join(ROOT_APP_DIR, "tmp/brakeman")
  OUTPUT_FILE = File.join(OUTPUT_DIR, "index.html")
  TEST_DIR = File.join(ROOT_APP_DIR, "test/brakeman")

  desc "Run Brakeman's tests generating the html."
  task :test do
    #cleanup the environment
    rm_rf OUTPUT_DIR
    mkdir OUTPUT_DIR

    #execute brakeman
    Rake::TestTask.new(:brakeman_test) do |t|
      t.libs << 'test'
      t.pattern = 'test/brakeman/**/*_test.rb'
      t.verbose = true
    end
    Rake::Task[:brakeman_test].invoke
  end

  desc "Run Brakeman's tests and open results in your browser."
  task :report do
    begin
      Rake::Task['brakeman:test'].invoke
    rescue RuntimeError => e
      puts e.message
    end
    #open the browser
    if PLATFORM['darwin']
      system("open #{OUTPUT_FILE}")
      puts "Opening Brakeman's report in the default browser"
    elsif PLATFORM[/linux/]
      system("xdg-open #{OUTPUT_FILE}")
      puts "Opening Brakeman's report in the default browser"
    else
      puts "You can view brakeman results at #{file}"
    end
  end

  desc 'Generate a default brakeman test'
  task :setup do
    mkdir_p TEST_DIR
    template_path = File.expand_path(File.join(File.dirname(__FILE__),  "../template", "brakeman_test.rb"))
    cp template_path, TEST_DIR
  end

end

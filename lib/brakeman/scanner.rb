require 'rubygems'
begin
  require 'ruby_parser'
  require 'haml'
  #require 'sass'
  require 'erb'
  require 'erubis'
  require 'brakeman/processor'
  require 'brakeman/blessing'
Dir.glob("processors/*.rb").each do |f|
  require File.join("brakeman", f.match(/processors.*/)[0])
end
rescue LoadError => e
  $stderr.puts e.message
  $stderr.puts "Please install the appropriate dependency."
  exit
end


#Erubis processor which ignores any output which is plain text.
class Brakeman::ScannerErubis < Erubis::Eruby
  include Erubis::NoTextEnhancer
end

class Brakeman::ErubisEscape < Brakeman::ScannerErubis
  include Erubis::EscapeEnhancer
end

#Scans the Rails application.
class Brakeman::Scanner
  RUBY_1_9 = !!(RUBY_VERSION =~ /^1\.9/)

  #Pass in path to the root of the Rails application
  def initialize path
    @path = path
    @app_path = File.join(path, "app")
    @processor = Brakeman::Processor.new
  end

  #Returns the Tracker generated from the scan
  def tracker
    @processor.tracked_events
  end

  #Process everything in the Rails application
  def process
    warn "Processing configuration..."
    process_config
    warn "Processing gems..."
    process_gems
    warn "Processing initializers..."
    process_initializers
    warn "Processing libs..."
    process_libs
    warn "Processing routes..."
    process_routes
    warn "Processing templates..."
    process_templates
    warn "Processing models..."
    process_models
    warn "Processing controllers..."
    process_controllers
    warn "Processing db migration files..."
    process_db
    tracker
  end

  def process_file file, &custom_processing
    file = File.join(@path, file) unless file.match /^\//
    return false unless File.exists? file
    content = File.read file

    #look for blessings
    Brakeman::Blessing.parse_string_for_blessings content

    #do the custom parsing
    begin
      yield RubyParser.new.parse(content), file
    rescue Racc::ParseError => e
      tracker.error e, "could not parse #{file}"
    rescue Exception => e
      tracker.error e.exception(e.message + "\nWhile processing #{file}"), e.backtrace
    end
    return true
  end


  #Process config/environment.rb and config/gems.rb
  #
  #Stores parsed information in tracker.config
  def process_config
    ["config/environment.rb", "config/gems.rb"].each do |file|
      process_file file do |parsed, f|
        @processor.process_config parsed
      end
    end

    if File.exists? "#@path/vendor/plugins/rails_xss" or 
      OPTIONS[:rails3] or OPTIONS[:escape_html] or
      (File.exists? "#@path/Gemfile" and File.read("#@path/Gemfile").include? "rails_xss")
      tracker.config[:escape_html] = true
      warn "[Notice] Escaping HTML by default"
    end
  end

  #Process Gemfile
  def process_gems
    if File.exists? "#@path/Gemfile"
      if File.exists? "#@path/Gemfile.lock"
        @processor.process_gems(RubyParser.new.parse(File.read("#@path/Gemfile")), File.read("#@path/Gemfile.lock"))
      else
        @processor.process_gems(RubyParser.new.parse(File.read("#@path/Gemfile")))
      end
    end
  end

  #Process all the .rb files in config/initializers/
  #
  #Adds parsed information to tracker.initializers
  def process_initializers
<<<<<<< HEAD:lib/brakeman/scanner.rb
    Dir.glob(File.join(@path, "config/initializers/**/*.rb")).sort.each do |f|
      process_file f do |parsed, file|
        @processor.process_initializer file, parsed
=======
    Dir.glob(@path + "/config/initializers/**/*.rb").sort.each do |f|
      begin
        @processor.process_initializer(f, RubyParser.new.parse(File.read(f)))
      rescue Racc::ParseError => e
        tracker.error e, "could not parse #{f}. There is probably a typo in the file. Test it with 'ruby_parse #{f}'"
      rescue Exception => e
        tracker.error e.exception(e.message + "\nWhile processing #{f}"), e.backtrace
>>>>>>> upstream/master:lib/scanner.rb
      end
    end
  end

  #Process all .rb in lib/
  #
  #Adds parsed information to tracker.libs.
  def process_libs
    Dir.glob(@path + "/lib/**/*.rb").sort.each do |f|
      process_file f do |parsed, file|
        @processor.process_lib parsed, file
    end
  end

  #Process config/routes.rb
  #
  #Adds parsed information to tracker.routes
  def process_routes
    warn "[Notice] No route information found"  unless File.exists? "#@path/config/routes.rb"
    process_file "config/routes.rb" do |parsed, file|
      @processor.process_routes parsed
    end
  end

  #Process all .rb files in controllers/
  #
  #Adds processed controllers to tracker.controllers
  def process_controllers
    Dir.glob(@app_path + "/controllers/**/*.rb").sort.each do |f|
      process_file f do |parsed, file|
        @processor.process_controller parsed, file
      end
    end

    tracker.controllers.each do |name, controller|
      @processor.process_controller_alias controller[:src]
    end
  end

  #Process all views and partials in views/
  #
  #Adds processed views to tracker.views
  def process_templates

    views_path = @app_path + "/views/**/*.{html.erb,html.haml,rhtml,js.erb}"
    $stdout.sync = true
    count = 0

    Dir.glob(views_path).sort.each do |f|
      count += 1
      type = f.match(/.*\.(erb|haml|rhtml)$/)[1].to_sym
      type = :erb if type == :rhtml
      name = template_path_to_name f
      text = File.read f
      Brakeman::Blessing.parse_string_for_blessings text, type

      begin
        if type == :erb
          if tracker.config[:escape_html]
            type = :erubis
            if OPTIONS[:rails3]
              src = Brakeman::RailsXSSErubis.new(text).src
            else
              src = Brakeman::ErubisEscape.new(text).src
            end
          elsif tracker.config[:erubis]
            type = :erubis
            src = Brakeman::ScannerErubis.new(text).src
          else
            src = ERB.new(text, nil, "-").src
            src.sub!(/^#.*\n/, '') if RUBY_1_9
          end

          parsed = RubyParser.new.parse src
        elsif type == :haml
          src = Haml::Engine.new(text,
                                 :escape_html => !!tracker.config[:escape_html]).precompiled
          parsed = RubyParser.new.parse src
        else
          tracker.error "Unkown template type in #{f}"
        end

        @processor.process_template(name, parsed, type, nil, f)

      rescue Racc::ParseError => e
        tracker.error e, "could not parse #{f}"
      rescue Haml::Error => e
        tracker.error e, ["While compiling HAML in #{f}"] << e.backtrace
      rescue Exception => e
        tracker.error e.exception(e.message + "\nWhile processing #{f}"), e.backtrace
      end
    end

    tracker.templates.keys.dup.each do |name|
      @processor.process_template_alias tracker.templates[name]
    end

  end

  #Convert path/filename to view name
  #
  # views/test/something.html.erb -> test/something
  def template_path_to_name path
    names = path.split("/")
    names.last.gsub!(/(\.(html|js)\..*|\.rhtml)$/, '')
    names[(names.index("views") + 1)..-1].join("/").to_sym
  end

  #Process all the .rb files in models/
  #
  #Adds the processed models to tracker.models
  def process_models
    Dir.glob(@app_path + "/models/*.rb").sort.each do |f|
      process_file f do |parsed, file|
        @processor.process_model(parsed, f)
      end
    end
  end

  #Process all the *_create*.rb files in db/migrate
  #
  #Adds the processed models to tracker.models
  def process_db
    Dir.glob(File.join(@app_path, "../db/migrate/*_create*.rb")).sort.each do |f|
      process_file f do |parsed, file|
        @processor.process_db(parsed, f)
      end
    end
  end

end

#This is from Rails 3 version of the Erubis handler
class Brakeman::RailsXSSErubis < ::Erubis::Eruby

  def add_preamble(src)
    # src << "_buf = ActionView::SafeBuffer.new;\n"
  end

  def add_text(src, text)
    if text == "\n"
      src << "\n"
    elsif text.include? "\n"
      lines = text.split("\n")
      if text.match(/\n\z/)
        lines.each do |line|
          src << "@output_buffer << ('" << escape_text(line) << "'.html_safe!);\n"
        end
      else
        lines[0..-2].each do |line|
          src << "@output_buffer << ('" << escape_text(line) << "'.html_safe!);\n"
        end
      
        src << "@output_buffer << ('" << escape_text(lines.last) << "'.html_safe!);"
      end
    else
      src << "@output_buffer << ('" << escape_text(text) << "'.html_safe!);"
    end
  end

  BLOCK_EXPR = /\s+(do|\{)(\s*\|[^|]*\|)?\s*\Z/

  def add_expr_literal(src, code)
    if code =~ BLOCK_EXPR
      src << '@output_buffer.append= ' << code
    else
      src << '@output_buffer.append= (' << code << ');'
    end
  end

  def add_stmt(src, code)
    if code =~ BLOCK_EXPR
      src << '@output_buffer.append_if_string= ' << code
    else
      super
    end
  end

  def add_expr_escaped(src, code)
    if code =~ BLOCK_EXPR
      src << "@output_buffer.safe_append= " << code
    else
      src << "@output_buffer.safe_concat(" << code << ");"
    end
  end

  #Add code to output buffer.
  def add_postamble(src)
    # src << '_buf.to_s'
  end
end


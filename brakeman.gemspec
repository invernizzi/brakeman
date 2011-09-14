# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{brakeman}
  s.version = "3.10.9"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [%q{Justin Collins}, %q{Luca Invernizzi}]
  s.date = %q{2011-09-14}
  s.description = %q{Brakeman detects security vulnerabilities in Ruby on Rails applications via static analysis.}
  s.email = [%q{}, %q{invernizzi.l@gmail.com}]
  s.executables = [%q{brakeman}]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    "CHANGES",
    "FEATURES",
    "LICENSE",
    "README.md",
    "Rakefile",
    "WARNING_TYPES",
    "bin/brakeman",
    "lib/brakeman.rb",
    "lib/brakeman/blessing.rb",
    "lib/brakeman/checks.rb",
    "lib/brakeman/checks/base_check.rb",
    "lib/brakeman/checks/check_basic_auth.rb",
    "lib/brakeman/checks/check_cross_site_scripting.rb",
    "lib/brakeman/checks/check_default_routes.rb",
    "lib/brakeman/checks/check_escape_function.rb",
    "lib/brakeman/checks/check_evaluation.rb",
    "lib/brakeman/checks/check_execute.rb",
    "lib/brakeman/checks/check_file_access.rb",
    "lib/brakeman/checks/check_filter_skipping.rb",
    "lib/brakeman/checks/check_forgery_setting.rb",
    "lib/brakeman/checks/check_mail_to.rb",
    "lib/brakeman/checks/check_mass_assignment.rb",
    "lib/brakeman/checks/check_model_attributes.rb",
    "lib/brakeman/checks/check_nested_attributes.rb",
    "lib/brakeman/checks/check_quote_table_name.rb",
    "lib/brakeman/checks/check_redirect.rb",
    "lib/brakeman/checks/check_render.rb",
    "lib/brakeman/checks/check_response_splitting.rb",
    "lib/brakeman/checks/check_send_file.rb",
    "lib/brakeman/checks/check_session_settings.rb",
    "lib/brakeman/checks/check_sql.rb",
    "lib/brakeman/checks/check_strip_tags.rb",
    "lib/brakeman/checks/check_validation_regex.rb",
    "lib/brakeman/checks/check_without_protection.rb",
    "lib/brakeman/format/style.css",
    "lib/brakeman/processor.rb",
    "lib/brakeman/processors/alias_processor.rb",
    "lib/brakeman/processors/base_processor.rb",
    "lib/brakeman/processors/config_processor.rb",
    "lib/brakeman/processors/controller_alias_processor.rb",
    "lib/brakeman/processors/controller_processor.rb",
    "lib/brakeman/processors/db_processor.rb",
    "lib/brakeman/processors/erb_template_processor.rb",
    "lib/brakeman/processors/erubis_template_processor.rb",
    "lib/brakeman/processors/gem_processor.rb",
    "lib/brakeman/processors/haml_template_processor.rb",
    "lib/brakeman/processors/lib/find_call.rb",
    "lib/brakeman/processors/lib/find_model_call.rb",
    "lib/brakeman/processors/lib/processor_helper.rb",
    "lib/brakeman/processors/lib/rails2_route_processor.rb",
    "lib/brakeman/processors/lib/rails3_route_processor.rb",
    "lib/brakeman/processors/lib/render_helper.rb",
    "lib/brakeman/processors/lib/route_helper.rb",
    "lib/brakeman/processors/library_processor.rb",
    "lib/brakeman/processors/model_processor.rb",
    "lib/brakeman/processors/output_processor.rb",
    "lib/brakeman/processors/params_processor.rb",
    "lib/brakeman/processors/route_processor.rb",
    "lib/brakeman/processors/template_alias_processor.rb",
    "lib/brakeman/processors/template_processor.rb",
    "lib/brakeman/report.rb",
    "lib/brakeman/scanner.rb",
    "lib/brakeman/tracker.rb",
    "lib/brakeman/util.rb",
    "lib/brakeman/version.rb",
    "lib/brakeman/warning.rb",
    "lib/brakeman/warning_types.rb",
    "lib/ruby_parser/ruby_lexer.rb",
    "lib/ruby_parser/ruby_parser.rb",
    "lib/tasks/brakeman_tasks.rake",
    "lib/template/brakeman_test.rb"
  ]
  s.homepage = %q{http://github.com/invernizzi/brakeman}
  s.require_paths = [%q{lib}]
  s.rubygems_version = %q{1.8.8}
  s.summary = %q{Security vulnerability scanner for Ruby on Rails.}
  s.test_files = [
    "test/rails2/app/controllers/application_controller.rb",
    "test/rails2/app/controllers/home_controller.rb",
    "test/rails2/app/controllers/other_controller.rb",
    "test/rails2/app/helpers/application_helper.rb",
    "test/rails2/app/helpers/home_helper.rb",
    "test/rails2/app/helpers/other_helper.rb",
    "test/rails2/app/models/account.rb",
    "test/rails2/app/models/user.rb",
    "test/rails2/config/boot.rb",
    "test/rails2/config/environment.rb",
    "test/rails2/config/environments/development.rb",
    "test/rails2/config/environments/production.rb",
    "test/rails2/config/environments/test.rb",
    "test/rails2/config/initializers/backtrace_silencers.rb",
    "test/rails2/config/initializers/cookie_verification_secret.rb",
    "test/rails2/config/initializers/inflections.rb",
    "test/rails2/config/initializers/mime_types.rb",
    "test/rails2/config/initializers/new_rails_defaults.rb",
    "test/rails2/config/initializers/security_defaults.rb",
    "test/rails2/config/initializers/session_store.rb",
    "test/rails2/config/routes.rb",
    "test/rails2/db/migrate/20110520193611_create_users.rb",
    "test/rails2/db/migrate/20110523184125_create_accounts.rb",
    "test/rails2/db/seeds.rb",
    "test/rails2/test/functional/home_controller_test.rb",
    "test/rails2/test/functional/other_controller_test.rb",
    "test/rails2/test/performance/browsing_test.rb",
    "test/rails2/test/test_helper.rb",
    "test/rails2/test/unit/account_test.rb",
    "test/rails2/test/unit/helpers/home_helper_test.rb",
    "test/rails2/test/unit/helpers/other_helper_test.rb",
    "test/rails2/test/unit/user_test.rb",
    "test/rails3.1/app/controllers/application_controller.rb",
    "test/rails3.1/app/controllers/users_controller.rb",
    "test/rails3.1/app/helpers/application_helper.rb",
    "test/rails3.1/app/helpers/users_helper.rb",
    "test/rails3.1/app/models/user.rb",
    "test/rails3.1/config/application.rb",
    "test/rails3.1/config/boot.rb",
    "test/rails3.1/config/environment.rb",
    "test/rails3.1/config/environments/development.rb",
    "test/rails3.1/config/environments/production.rb",
    "test/rails3.1/config/environments/test.rb",
    "test/rails3.1/config/initializers/backtrace_silencers.rb",
    "test/rails3.1/config/initializers/inflections.rb",
    "test/rails3.1/config/initializers/mime_types.rb",
    "test/rails3.1/config/initializers/secret_token.rb",
    "test/rails3.1/config/initializers/session_store.rb",
    "test/rails3.1/config/initializers/wrap_parameters.rb",
    "test/rails3.1/config/routes.rb",
    "test/rails3.1/db/migrate/20110908172338_create_users.rb",
    "test/rails3.1/db/seeds.rb",
    "test/rails3.1/test/functional/users_controller_test.rb",
    "test/rails3.1/test/performance/browsing_test.rb",
    "test/rails3.1/test/test_helper.rb",
    "test/rails3.1/test/unit/helpers/users_helper_test.rb",
    "test/rails3.1/test/unit/user_test.rb",
    "test/rails3/app/controllers/application_controller.rb",
    "test/rails3/app/controllers/home_controller.rb",
    "test/rails3/app/controllers/other_controller.rb",
    "test/rails3/app/helpers/application_helper.rb",
    "test/rails3/app/helpers/home_helper.rb",
    "test/rails3/app/helpers/other_helper.rb",
    "test/rails3/app/models/account.rb",
    "test/rails3/app/models/user.rb",
    "test/rails3/config/application.rb",
    "test/rails3/config/boot.rb",
    "test/rails3/config/environment.rb",
    "test/rails3/config/environments/development.rb",
    "test/rails3/config/environments/production.rb",
    "test/rails3/config/environments/test.rb",
    "test/rails3/config/initializers/backtrace_silencers.rb",
    "test/rails3/config/initializers/inflections.rb",
    "test/rails3/config/initializers/mime_types.rb",
    "test/rails3/config/initializers/secret_token.rb",
    "test/rails3/config/initializers/session_store.rb",
    "test/rails3/config/routes.rb",
    "test/rails3/db/seeds.rb",
    "test/rails3/test/functional/home_controller_test.rb",
    "test/rails3/test/functional/other_controller_test.rb",
    "test/rails3/test/performance/browsing_test.rb",
    "test/rails3/test/test_helper.rb",
    "test/rails3/test/unit/helpers/home_helper_test.rb",
    "test/rails3/test/unit/helpers/other_helper_test.rb",
    "test/test.rb"
  ]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>, [">= 2.2"])
      s.add_runtime_dependency(%q<ruby2ruby>, [">= 1.2.4"])
      s.add_runtime_dependency(%q<ruport>, [">= 1.6.3"])
      s.add_runtime_dependency(%q<erubis>, [">= 2.6.5"])
      s.add_runtime_dependency(%q<haml>, [">= 3.0.12"])
      s.add_runtime_dependency(%q<sass>, [">= 0"])
      s.add_runtime_dependency(%q<i18n>, [">= 0"])
    else
      s.add_dependency(%q<activesupport>, [">= 2.2"])
      s.add_dependency(%q<ruby2ruby>, [">= 1.2.4"])
      s.add_dependency(%q<ruport>, [">= 1.6.3"])
      s.add_dependency(%q<erubis>, [">= 2.6.5"])
      s.add_dependency(%q<haml>, [">= 3.0.12"])
      s.add_dependency(%q<sass>, [">= 0"])
      s.add_dependency(%q<i18n>, [">= 0"])
    end
  else
    s.add_dependency(%q<activesupport>, [">= 2.2"])
    s.add_dependency(%q<ruby2ruby>, [">= 1.2.4"])
    s.add_dependency(%q<ruport>, [">= 1.6.3"])
    s.add_dependency(%q<erubis>, [">= 2.6.5"])
    s.add_dependency(%q<haml>, [">= 3.0.12"])
    s.add_dependency(%q<sass>, [">= 0"])
    s.add_dependency(%q<i18n>, [">= 0"])
  end
end


require 'bundler'
Bundler.require(:development)

SimpleCov.start do
  coverage_dir "tmp/coverage"

  add_filter "/spec/"
  add_filter "/vendor/"

  minimum_coverage 99.6
  refuse_coverage_drop
end if ENV["coverage"]

require 'http_server_manager/test_support'

require_relative '../lib/http_stub/rake/task_generators'
require_relative '../lib/http_stub'
require_relative '../examples/configurer_with_class_stub'
require_relative '../examples/configurer_with_deprecated_activator'
require_relative '../examples/configurer_with_class_scenario'
require_relative '../examples/configurer_with_class_scenarios'
require_relative '../examples/configurer_with_initialize_callback'
require_relative '../examples/configurer_with_complex_initializer'
require_relative '../examples/configurer_with_response_defaults'
require_relative '../examples/configurer_with_triggers'
require_relative '../examples/configurer_with_file_responses'

HttpStub::Server::Daemon.log_dir = ::File.expand_path('../../tmp/log', __FILE__)
HttpStub::Server::Daemon.pid_dir = ::File.expand_path('../../tmp/pids', __FILE__)

HttpServerManager.logger = HttpServerManager::Test::SilentLogger

module HttpStub

  module Spec
    RESOURCES_DIR = ::File.expand_path('../resources', __FILE__)
  end

end

require_relative 'support/stub_fixture'
require_relative 'support/scenario_fixture'
require_relative 'support/server_integration'
require_relative 'support/configurer_integration'

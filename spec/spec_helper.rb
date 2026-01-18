# frozen_string_literal: true

require 'bundler/setup'

Bundler.setup

require 'active_job'
require 'active_support/core_ext/array/wrap'
require 'active_support/core_ext/object/try'
require 'debug'
require 'factory_bot'
require 'faker'
require 'servo'
require 'sidekiq'

ActiveJob::Base.queue_adapter = :inline

File.expand_path(__dir__).tap do |root_dir|
  Dir[File.join(root_dir, 'config/initializers/**/*.rb')].each { |f| require f }
  Dir[File.join(root_dir, 'support', '**', '*.rb')].each { |f| require f }
end

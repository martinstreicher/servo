# frozen_string_literal: true

require 'active_model'
require 'active_support'
require 'interactor'
require 'zeitwerk'
require 'servo/version'

loader = Zeitwerk::Loader.for_gem
loader.log! if ENV.fetch('SERVO_DEBUG_LOADER', nil).present?
loader.setup

module Servo
  class UndeclaredContextVariableError < StandardError; end
end

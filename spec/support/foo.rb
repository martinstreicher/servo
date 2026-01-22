# frozen_string_literal: true

require 'active_job'

module Servo
  class Foo < Servo::Jobs::ActiveJob
    def call
      true
    end
  end
end

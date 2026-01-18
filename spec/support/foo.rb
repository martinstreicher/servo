# frozen_string_literal: true

require 'active_job'

module Servo
  class Foo < Servo::Jobs::ActiveJob
    def perform
      true
    end
  end
end

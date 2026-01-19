# frozen_string_literal: true

class TestJob < Servo::Jobs::ActiveJob
  def call
    context.result = true
    false
  end
end

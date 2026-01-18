# frozen_string_literal: true

class TestJob < Servo::Jobs::ActiveJob
  def perform
    context.result = true
    false
  end
end

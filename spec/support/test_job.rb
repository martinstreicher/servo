# frozen_string_literal: true

TestJob = Class.new(Servo::Jobs::ActiveJob) do
  def call
    context.result = true
    false
  end
end

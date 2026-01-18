# frozen_string_literal: true

class SidekiqJobJig < Servo::Jobs::SidekiqJob
  include Sidekiq::Worker

  def perform
    true
  end
end

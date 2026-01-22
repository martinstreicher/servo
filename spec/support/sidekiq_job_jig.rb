# frozen_string_literal: true

class SidekiqJobJig < Servo::Jobs::SidekiqJob
  include Sidekiq::Worker

  def call
    true
  end
end

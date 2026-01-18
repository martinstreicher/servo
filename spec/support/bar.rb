# frozen_string_literal: true

require 'sidekiq'

module Servo
  class Bar < Jobs::SidekiqJob
    def perform
      true
    end
  end
end

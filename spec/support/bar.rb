# frozen_string_literal: true

require 'sidekiq'

module Servo
  class Bar < Jobs::SidekiqJob
    def call
      true
    end
  end
end

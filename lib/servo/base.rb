# frozen_string_literal: true

module Servo
  ##
  # Base class for creating interactors.
  #
  # Provides a convenient alternative to `include Servo::Callable`.
  # Both approaches are equivalent.
  #
  # Example:
  #
  #   class CreateUser < Servo::Base
  #     input  :email, type: String
  #     input  :name,  type: String
  #     output :user
  #
  #     validates :email, presence: true
  #
  #     def call
  #       self.user = User.create!(email: email, name: name)
  #     end
  #   end
  #
  class Base
    include Callable
  end
end

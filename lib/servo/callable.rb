# frozen_string_literal: true

require_relative 'callable/call_override'
require_relative 'callable/context_restriction'
require_relative 'callable/dsl'
require_relative 'callable/type_checker'

module Servo
  ##
  # Provides a base module for building interactors with validation and context management.
  #
  # This implementation is based on the interactor gem but adds features to make usage
  # more uniform:
  #
  # * Define only the `call` method to implement your interactor's unique logic.
  #
  # * Integrates ActiveModel::Validations to validate any or all of the params
  #   passed to your interactor. If any validations fail, the `call` method
  #   does not run.
  #
  # * Use `input` and `output` DSL methods to declare allowed context variables.
  #   Context restriction is enabled by default; use `unrestrict_context!` to disable.
  #
  # * The return value of every invocation is of uniform shape:
  #   - `result.success?` is `true` if the interactor ran without issue
  #   - `result.data` contains any artifacts of the interactor's work
  #   - `result.failure?` is `true` if the interactor failed
  #   - `result.errors` contains validation errors (ActiveModel::Errors)
  #   - `result.error_messages` contains the full error messages as an array
  #
  # Example:
  #
  #   class GreetUser
  #     include Servo::Callable
  #
  #     input  :name, type: String
  #     output :greeting
  #
  #     validates :name, presence: true
  #
  #     def call
  #       self.greeting = "Hello, #{name}!"
  #       greeting
  #     end
  #   end
  #
  #   result = GreetUser.call(name: 'World')
  #   result.success?  # => true
  #   result.data      # => "Hello, World!"
  #   result.greeting  # => "Hello, World!"
  #
  module Callable
    extend ActiveSupport::Concern

    included do
      include Interactor
      include ActiveModel::Validations
      include ActiveModel::Validations::Callbacks
      include ActiveSupport::Callbacks
      include Callable::ContextRestriction
      extend Callable::Dsl
      prepend Callable::CallOverride

      define_callbacks :call

      class_attribute :_allowed_inputs, default: Set.new
      class_attribute :_allowed_outputs, default: Set.new
      class_attribute :_restrict_context, default: true
      class_attribute :_type_constraints, default: {}
    end

    class_methods do
      def call_later(interactor_args: {}, job_args: {})
        Jobs::AsyncInteractorJob.set(**job_args).perform_later(name, interactor_args)
      end
    end

    def method_missing(method, *, &) = context.public_send(method, *, &)

    def respond_to_missing?(method_name, _include_private = false)
      super || context.respond_to?(method_name)
    end
  end
end

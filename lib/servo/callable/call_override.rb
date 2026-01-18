# frozen_string_literal: true

module Servo
  module Callable
    ##
    # Overrides Interactor's call method to integrate validation,
    # callbacks, and context restriction.
    #
    # This module is prepended after Interactor is included so that
    # our call method takes precedence in the method lookup chain.
    #
    module CallOverride
      def call
        @initial_context = context.dup
        apply_context_restrictions! if self.class.restrict_context?

        if valid?
          run_callbacks :perform do
            result = perform
            context.result ||= result
          end
        end

        fail_if_errors
        context.data = context.result
      end

      private

      def fail_if_errors
        return if errors.empty?

        context.fail!(
          error_messages: errors.full_messages,
          errors:         errors
        )
      end
    end
  end
end

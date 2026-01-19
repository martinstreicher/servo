# frozen_string_literal: true

module Servo
  module Callable
    ##
    # Overrides Interactor's call method to integrate validation,
    # callbacks, and context restriction.
    #
    # This module is prepended after Interactor is included to
    # force this call method to take precedence in the method lookup chain.
    #
    # Developers implement the `call` instance method for their business logic.
    # The framework renames it to `_call` and wraps it with validations/callbacks.
    #
    module CallOverride
      def self.prepended(base)
        base.class_eval do
          # When a subclass defines `call`, alias it to `_call` so we can wrap it
          def self.method_added(method_name)
            return unless method_name == :call
            return if @_aliasing_call

            @_aliasing_call = true
            alias_method :_call, :call
            remove_method :call
            @_aliasing_call = false
          end
        end
      end

      # Default implementation if developer hasn't defined call yet
      def _call
        raise NotImplementedError, "Method #call must be implemented in #{self.class.name}"
      end

      # Intercepts Interactor's instance call method.
      # Runs validations, callbacks, then invokes the developer's _call.
      def call
        apply_context_restrictions! if self.class.restrict_context?

        if valid?
          run_callbacks :call do
            result = _call
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

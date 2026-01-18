# frozen_string_literal: true

module Servo
  module Callable
    ##
    # Restricts context functionality.
    #
    # When `restrict_context!` is called on a class, this module
    # intercepts writes to the context and raises an error if
    # the key is not declared with `input` or `output`.
    ##
    module ContextRestriction
      private

      def apply_context_restrictions!
        allowed = self.class.allowed_context_keys
        interactor_class = self.class

        context.singleton_class.define_method(:method_missing) do |method, *args, &block|
          if method.to_s.end_with?('=')
            key = method.to_s.chomp('=').to_sym

            unless allowed.include?(key)
              fail(
                Servo::UndeclaredContextVariableError,
                "Cannot set '#{key}' on #{interactor_class.name} context. " \
                "Declare it with 'input :#{key}' or 'output :#{key}'"
              )
            end
          end

          super(method, *args, &block)
        end
      end
    end
  end
end

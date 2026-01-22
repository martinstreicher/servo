# frozen_string_literal: true

module Servo
  module Callable
    ##
    # Leverage the `method_added` hook to intercept the user-defined `call`
    # and wrap it with validation, callback logic, and context restrictions.
    # Developers implement the `call` instance method per standard
    # Interactor gem development.
    ##
    module CallOverride
      WRAPPING_LOCK = Mutex.new

      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # The @_servo_wrapping_call flag prevents infinite recursion since
        # define_method(:call) triggers method_added(:call) again.
        # This check must happen before the mutex to avoid deadlock.
        def method_added(method_name)
          super

          return unless method_name == :call
          return if @_servo_wrapping_call

          WRAPPING_LOCK.synchronize do
            @_servo_wrapping_call = true

            user_call_method = instance_method(:call)

            define_method(:call) do
              apply_context_restrictions! if self.class.restrict_context?

              if valid?
                run_callbacks :call do
                  result = user_call_method.bind_call(self)
                  context.result ||= result
                end
              end

              fail_if_errors
              context.data = context.result
            end
          ensure
            @_servo_wrapping_call = false
          end
        end
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

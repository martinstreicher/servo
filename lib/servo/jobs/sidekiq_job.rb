# frozen_string_literal: true

module Servo
  module Jobs
    ##
    # Base class for Sidekiq-based interactors.
    #
    # Subclasses define `perform` for their business logic, just like
    # plain Servo::Callable classes. When the job is enqueued and executed,
    # the arguments are passed to `call` which invokes `perform`.
    #
    # Example:
    #
    #   class ProcessOrderJob < Servo::Jobs::SidekiqJob
    #     input :order_id, type: Integer
    #
    #     validates :order_id, presence: true
    #
    #     def perform
    #       order = Order.find(order_id)
    #       order.process!
    #     end
    #   end
    #
    #   # Enqueue the job
    #   ProcessOrderJob.perform_async(order_id: 123)
    #
    class SidekiqJob
      include Callable

      if defined?(Sidekiq)
        include Sidekiq::Worker

        # Module to intercept Sidekiq's perform call and route to Callable.
        module PerformInterceptor
          def perform(*_args, **)
            self.class.call(**)
          end
        end

        prepend PerformInterceptor
      end
    end
  end
end

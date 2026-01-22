# frozen_string_literal: true

require 'active_job'

module Servo
  module Jobs
    ##
    # Base class for ActiveJob-based interactors.
    #
    # Subclasses define `call` for their business logic, just like
    # plain Servo::Callable classes. When the job is enqueued and executed,
    # ActiveJob's `perform` method routes to the Servo `call` method.
    #
    # Example:
    #
    #   class SendWelcomeEmailJob < Servo::Jobs::ActiveJob
    #     input :user_id, type: Integer
    #
    #     validates :user_id, presence: true
    #
    #     def call
    #       user = User.find(user_id)
    #       UserMailer.welcome(user).deliver_now
    #     end
    #   end
    #
    #   # Enqueue the job
    #   SendWelcomeEmailJob.perform_later(user_id: 123)
    #
    #   # Or run immediately (returns the interactor context)
    #   result = SendWelcomeEmailJob.call(user_id: 123)
    #   result.success?
    #
    class ActiveJob < ::ActiveJob::Base
      include Callable

      # Override class-level perform_now to return interactor context
      class << self
        def perform_now(**)
          call(**)
        end
      end

      # Instance perform is called by ActiveJob when job runs asynchronously.
      # For async jobs, we just execute and don't return context.
      def perform(*_args, **)
        self.class.call(**)
      end
    end
  end
end

# frozen_string_literal: true

require 'active_job'

module Servo
  module Jobs
    class AsyncInteractorJob < ::ActiveJob::Base
      queue_as :default

      class UninitializedInteractorClassName < StandardError
        def initialize(class_name, arguments)
          super("Failed to initialize interactor class: #{class_name}, arguments: #{arguments}")
        end
      end

      class UnsuccessfulAsyncInteractorExecution < StandardError
        def initialize(class_name, errors, arguments)
          super("Interactor #{class_name} failed with errors: #{errors.to_hash}, arguments: #{arguments}")
        end
      end

      def perform(interactor_class_name, arguments_hash = {})
        klass = interactor_class_name.safe_constantize
        fail UninitializedInteractorClassName.new(interactor_class_name, arguments_hash) if klass.nil?

        result = klass.call(**arguments_hash)
        return unless result.failure?

        fail UnsuccessfulAsyncInteractorExecution.new(interactor_class_name, result.errors, arguments_hash)
      end
    end
  end
end

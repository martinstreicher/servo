# frozen_string_literal: true

module Servo
  module Controllers
    module Concerns
      module Reply
        extend ActiveSupport::Concern

        included do
          def reply(condition:, record:, errors: [], failure: :unprocessable_content, success: :ok)
            if condition
              render json: record, status: success
              return
            end

            error_list   = errors.try(:full_messages)
            error_list ||= record.try(:errors).try(:full_messages).presence
            error_list ||= Array.wrap(errors).presence
            error_list ||= ['Unknown error']

            render json: { errors: error_messages(error_list) }, status: failure
          end

          alias_method :rejoin, :reply

          private

          def error_messages(errors)
            messages   = errors.try(:full_messages)
            messages ||= Array.wrap(errors).presence
            messages ||= 'Unknown error'

            Array
              .wrap(messages)
              .join(' -- ')
              .capitalize
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Servo::Controllers::Concerns::Reply do
  let(:controller_class) do
    Class.new do
      include Servo::Controllers::Concerns::Reply

      attr_accessor :rendered_json, :rendered_status

      def render(json:, status:)
        @rendered_json   = json
        @rendered_status = status
      end
    end
  end

  let(:controller) { controller_class.new }

  describe '#reply' do
    context 'when condition is true (success)' do
      let(:record) { { id: 1, name: 'Test' } }

      it 'renders the record as JSON with success status' do
        controller.reply(condition: true, record: record)

        expect(controller.rendered_json).to eq(record)
        expect(controller.rendered_status).to eq(:ok)
      end

      it 'uses custom success status when provided' do
        controller.reply(condition: true, record: record, success: :created)

        expect(controller.rendered_status).to eq(:created)
      end
    end

    context 'when condition is false (failure)' do
      let(:record) { { id: 1, name: 'Test' } }

      it 'renders error JSON with failure status' do
        controller.reply(condition: false, record: record)

        expect(controller.rendered_json).to have_key(:errors)
        expect(controller.rendered_status).to eq(:unprocessable_content)
      end

      it 'uses custom failure status when provided' do
        controller.reply(condition: false, failure: :bad_request, record: record)

        expect(controller.rendered_status).to eq(:bad_request)
      end

      context 'with explicit errors array' do
        it 'formats error messages from array' do
          controller.reply(
            condition: false,
            errors:    ['Error one', 'Error two'],
            record:    record
          )

          expect(controller.rendered_json[:errors]).to eq('Error one -- error two')
        end
      end

      context 'with errors responding to full_messages' do
        let(:errors_object) do
          double('errors', full_messages: ['Name is invalid', 'Email is required'])
        end

        it 'extracts full_messages from errors object' do
          controller.reply(condition: false, errors: errors_object, record: record)

          expect(controller.rendered_json[:errors]).to eq('Name is invalid -- email is required')
        end
      end

      context 'with record that has errors' do
        let(:record_errors) do
          double('errors', full_messages: ['Record error one', 'Record error two'])
        end

        let(:record_with_errors) do
          double('record', errors: record_errors)
        end

        it 'extracts errors from record when no explicit errors provided' do
          controller.reply(condition: false, record: record_with_errors)

          expect(controller.rendered_json[:errors]).to eq('Record error one -- record error two')
        end
      end

      context 'with no errors available' do
        it 'renders unknown error message' do
          controller.reply(condition: false, errors: [], record: record)

          expect(controller.rendered_json[:errors]).to eq('Unknown error')
        end
      end
    end
  end

  describe '#rejoin' do
    it 'is an alias for #reply' do
      expect(controller.method(:rejoin)).to eq(controller.method(:reply))
    end
  end
end

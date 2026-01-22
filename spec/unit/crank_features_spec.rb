# frozen_string_literal: true

RSpec.describe 'Servo::Callable result handling' do
  let(:klass) do
    Class.new do
      Object.const_set(FactoryBot.generate(:class_name), self)
      include Servo::Callable

      def call
        context.result = true
        false
      end
    end
  end

  context 'when a task sets its own result in the interactor context' do
    it 'does not change the result' do
      expect(klass.call.result).to be_truthy
    end
  end
end

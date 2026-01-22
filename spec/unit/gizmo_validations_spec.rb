# frozen_string_literal: true

RSpec.describe 'Servo::Callable validations' do
  let(:klass) do
    Class.new do
      Object.const_set(FactoryBot.generate(:class_name), self)
      include Servo::Callable

      validates :name, presence: true

      def call
        true
      end
    end
  end

  context 'when called with valid parameters' do
    it 'executes the task' do
      expect(klass.call(name: :name)).to be_success
    end

    it 'returns a result in the context' do
      expect(klass.call(name: :name).result).to be_truthy
    end

    it 'returns no validation errors in the context' do
      expect(klass.call(name: :name).errors).to be_nil
    end

    it 'returns no error messages in the context' do
      expect(klass.call(name: :name).error_messages).to be_nil
    end
  end

  context 'when called with invalid parameters' do
    it 'does not execute the task' do
      expect(klass.call(name: nil)).to be_failure
    end

    it 'does not return a result in the context' do
      expect(klass.call(name: nil).result).to be_nil
    end

    it 'returns the validation errors in the context' do
      expect(klass.call(name: nil).errors.to_hash).to eq(name: ["can't be blank"])
    end

    it 'returns the validation error messages in the context' do
      expect(klass.call(name: nil).error_messages).to(
        contain_exactly("Name can't be blank")
      )
    end
  end
end

# frozen_string_literal: true

RSpec.describe 'Servo::Callable without call method' do
  let(:klass) do
    Class.new do
      Object.const_set(FactoryBot.generate(:class_name), self)
      include Servo::Callable
    end
  end

  it 'succeeds with nil result when call is not defined' do
    result = klass.call
    expect(result).to be_success
    expect(result.data).to be_nil
  end
end

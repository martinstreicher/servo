# frozen_string_literal: true

RSpec.describe 'Servo::Jobs::ActiveJob' do
  before(:all) do
    ActiveJob::Base.queue_adapter = :inline
  end

  let(:klass) do
    Class.new(Servo::Jobs::ActiveJob) do
      Object.const_set(FactoryBot.generate(:class_name), self)

      def call
        true
      end
    end
  end

  it 'includes the ActiveJob modules' do
    expect(klass.ancestors).to include(ActiveJob::Execution)
  end

  it 'responds to perform_now' do
    expect(klass).to respond_to(:perform_now)
  end

  it 'executes a job and returns a successful result' do
    result = klass.perform_now
    expect(result).to be_success
    expect(result.data).to be_truthy
  end
end

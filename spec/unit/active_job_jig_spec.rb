# frozen_string_literal: true

RSpec.describe ActiveJobJig do
  before(:all) do
    ActiveJob::Base.queue_adapter = :inline
  end

  it 'includes the ActiveJob modules' do
    expect(described_class.ancestors).to include(ActiveJob::Execution)
  end

  it 'responds to perform_now' do
    expect(described_class).to respond_to(:perform_now)
  end

  it 'executes a job and returns a successful result' do
    result = described_class.perform_now
    expect(result).to be_success
    expect(result.data).to be_truthy
  end
end

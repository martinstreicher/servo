# frozen_string_literal: true

RSpec.describe TestJob do
  it 'executes and returns a result' do
    result = described_class.perform_now
    expect(result).to be_success
    expect(result.result).to be_truthy
  end
end

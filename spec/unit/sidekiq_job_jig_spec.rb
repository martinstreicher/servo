# frozen_string_literal: true

RSpec.describe SidekiqJobJig do
  it 'provides a perform method' do
    expect(described_class.new).to respond_to(:perform)
  end
end

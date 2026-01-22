# frozen_string_literal: true

RSpec.describe 'Servo::Callable callbacks' do
  describe 'before and after callbacks' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input  :value
        output :log

        set_callback :call, :before, :log_before
        set_callback :call, :after, :log_after

        def call
          self.log ||= []
          log << 'perform'
          value
        end

        private

        def log_after
          log << 'after'
        end

        def log_before
          self.log ||= []
          log << 'before'
        end
      end
    end

    it 'executes callbacks in order' do
      result = klass.call(value: 'test')

      expect(result).to be_success
      expect(result.log).to eq(%w(before perform after))
    end

    it 'returns the call result as data' do
      result = klass.call(value: 'test')

      expect(result.data).to eq('test')
    end
  end

  describe 'around callbacks' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input  :value
        output :log

        set_callback :call, :around, :wrap_call

        def call
          self.log ||= []
          log << 'perform'
          value
        end

        private

        def wrap_call
          self.log ||= []
          log << 'around_before'
          yield
          log << 'around_after'
        end
      end
    end

    it 'wraps the call execution' do
      result = klass.call(value: 'wrapped')

      expect(result).to be_success
      expect(result.log).to eq(%w(around_before perform around_after))
    end
  end
end

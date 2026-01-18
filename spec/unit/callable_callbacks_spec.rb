# frozen_string_literal: true

RSpec.describe 'Servo::Callable callbacks' do
  before(:all) do
    class CallbackInteractor
      include Servo::Callable

      input  :value
      output :log

      set_callback :perform, :before, :log_before
      set_callback :perform, :after, :log_after

      def perform
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

    class AroundCallbackInteractor
      include Servo::Callable

      input  :value
      output :log

      set_callback :perform, :around, :wrap_perform

      def perform
        self.log ||= []
        log << 'perform'
        value
      end

      private

      def wrap_perform
        self.log ||= []
        log << 'around_before'
        yield
        log << 'around_after'
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :AroundCallbackInteractor)
    Object.send(:remove_const, :CallbackInteractor)
  end

  describe 'before and after callbacks' do
    it 'executes callbacks in order' do
      result = CallbackInteractor.call(value: 'test')

      expect(result).to be_success
      expect(result.log).to eq(%w(before perform after))
    end

    it 'returns the perform result as data' do
      result = CallbackInteractor.call(value: 'test')

      expect(result.data).to eq('test')
    end
  end

  describe 'around callbacks' do
    it 'wraps the perform execution' do
      result = AroundCallbackInteractor.call(value: 'wrapped')

      expect(result).to be_success
      expect(result.log).to eq(%w(around_before perform around_after))
    end
  end
end

# frozen_string_literal: true

RSpec.describe 'Servo::Callable.call_later' do
  before(:all) do
    ActiveJob::Base.queue_adapter = :test

    class AsyncTestInteractor
      include Servo::Callable

      input  :message
      output :result

      def perform
        self.result = "Processed: #{message}"
        result
      end
    end

    class FailingAsyncInteractor
      include Servo::Callable

      input :value

      validates :value, presence: true

      def perform
        value
      end
    end
  end

  after(:all) do
    Object.send(:remove_const, :AsyncTestInteractor)
    Object.send(:remove_const, :FailingAsyncInteractor)
    ActiveJob::Base.queue_adapter = :inline
  end

  describe '.call_later' do
    before do
      ActiveJob::Base.queue_adapter.enqueued_jobs.clear
    end

    it 'enqueues an AsyncInteractorJob' do
      AsyncTestInteractor.call_later(interactor_args: { message: 'Hello' })

      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.size).to eq(1)

      job = ActiveJob::Base.queue_adapter.enqueued_jobs.first
      expect(job[:job]).to eq(Servo::Jobs::AsyncInteractorJob)
    end

    it 'passes the interactor class name and arguments to the job' do
      AsyncTestInteractor.call_later(interactor_args: { message: 'Test message' })

      job = ActiveJob::Base.queue_adapter.enqueued_jobs.first
      expect(job[:args]).to eq(['AsyncTestInteractor', { message: 'Test message' }])
    end

    it 'accepts job_args to configure the job' do
      AsyncTestInteractor.call_later(
        interactor_args: { message: 'Delayed' },
        job_args:        { queue: 'high_priority', wait: 5.minutes }
      )

      job = ActiveJob::Base.queue_adapter.enqueued_jobs.first
      expect(job[:queue]).to eq('high_priority')
      expect(job[:at]).to be_present
    end
  end

  describe Servo::Jobs::AsyncInteractorJob do
    it 'executes the interactor synchronously when performed' do
      expect(AsyncTestInteractor).to receive(:call).with(message: 'Hello').and_call_original

      described_class.perform_now('AsyncTestInteractor', { message: 'Hello' })
    end

    it 'raises UninitializedInteractorClassName for invalid class names' do
      expect do
        described_class.perform_now('NonExistentInteractor', {})
      end.to raise_error(
        Servo::Jobs::AsyncInteractorJob::UninitializedInteractorClassName,
        /Failed to initialize interactor class: NonExistentInteractor/
      )
    end

    it 'raises UnsuccessfulAsyncInteractorExecution when interactor fails' do
      expect do
        described_class.perform_now('FailingAsyncInteractor', { value: nil })
      end.to raise_error(
        Servo::Jobs::AsyncInteractorJob::UnsuccessfulAsyncInteractorExecution,
        /Interactor FailingAsyncInteractor failed with errors/
      )
    end

    it 'completes successfully when interactor succeeds' do
      expect do
        described_class.perform_now('AsyncTestInteractor', { message: 'Success' })
      end.not_to raise_error
    end
  end
end

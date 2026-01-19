# frozen_string_literal: true

RSpec.describe Servo::Callable do
  describe 'input DSL' do
    before(:all) do
      # Define named class to avoid anonymous class issues with ActiveModel
      class InputDslInteractor
        include Servo::Callable

        input :name
        input :age, type: Integer

        def call
          "Hello, #{name}!"
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :InputDslInteractor)
    end

    it 'allows accessing declared inputs' do
      result = InputDslInteractor.call(age: 25, name: 'World')
      expect(result).to be_success
      expect(result.data).to eq('Hello, World!')
    end

    it 'validates type constraints when specified' do
      result = InputDslInteractor.call(age: 'not an integer', name: 'World')
      expect(result).to be_failure
      expect(result.errors[:age]).to include('must be a Integer')
    end

    it 'allows nil values even with type constraints' do
      result = InputDslInteractor.call(age: nil, name: 'World')
      expect(result).to be_success
    end
  end

  describe 'output DSL' do
    before(:all) do
      class OutputDslInteractor
        include Servo::Callable

        input  :multiplier
        output :computed_value

        def call
          self.computed_value = 10 * (multiplier || 1)
          computed_value
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :OutputDslInteractor)
    end

    it 'allows setting declared outputs' do
      result = OutputDslInteractor.call(multiplier: 5)
      expect(result).to be_success
      expect(result.computed_value).to eq(50)
    end
  end

  describe 'union types' do
    before(:all) do
      class UnionTypeInteractor
        include Servo::Callable

        input :date_value, type: [String, Date]

        def call
          date_value
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :UnionTypeInteractor)
    end

    it 'accepts String type' do
      result = UnionTypeInteractor.call(date_value: '2024-01-01')
      expect(result).to be_success
    end

    it 'accepts Date type' do
      result = UnionTypeInteractor.call(date_value: Date.today)
      expect(result).to be_success
    end

    it 'rejects other types' do
      result = UnionTypeInteractor.call(date_value: 12_345)
      expect(result).to be_failure
      expect(result.errors[:date_value]).to include('must be a String or Date')
    end
  end

  describe 'context restriction (default behavior)' do
    before(:all) do
      class RestrictedInteractor
        include Servo::Callable

        input  :allowed_input
        output :allowed_output

        def call
          self.allowed_output = 'set'
          'done'
        end
      end

      class UnrestrictedInteractor
        include Servo::Callable

        unrestrict_context!

        def call
          context.anything = 'allowed'
          'done'
        end
      end

      class UndeclaredVarInteractor
        include Servo::Callable

        input :name

        def call
          context.undeclared_var = 'bad'
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :RestrictedInteractor)
      Object.send(:remove_const, :UnrestrictedInteractor)
      Object.send(:remove_const, :UndeclaredVarInteractor)
    end

    it 'allows setting declared inputs and outputs' do
      result = RestrictedInteractor.call(allowed_input: 'test')
      expect(result).to be_success
      expect(result.allowed_output).to eq('set')
    end

    it 'raises error when setting undeclared context variable' do
      expect { UndeclaredVarInteractor.call(name: 'test') }.to raise_error(
        Servo::UndeclaredContextVariableError,
        /Cannot set 'undeclared_var'/
      )
    end

    it 'allows any context variable when unrestricted' do
      result = UnrestrictedInteractor.call
      expect(result).to be_success
      expect(result.anything).to eq('allowed')
    end
  end

  describe 'inheritance' do
    before(:all) do
      class ParentInteractor
        include Servo::Callable

        input :parent_input

        def call
          parent_input
        end
      end

      class ChildInteractor < ParentInteractor
        input :child_input

        def call
          "#{parent_input} + #{child_input}"
        end
      end
    end

    after(:all) do
      Object.send(:remove_const, :ChildInteractor)
      Object.send(:remove_const, :ParentInteractor)
    end

    it 'inherits inputs from parent class' do
      result = ChildInteractor.call(child_input: 'child', parent_input: 'parent')
      expect(result).to be_success
      expect(result.data).to eq('parent + child')
    end
  end

  describe 'allowed_context_keys' do
    before(:all) do
      class KeysInteractor
        include Servo::Callable

        input  :input1
        input  :input2
        output :output1
      end
    end

    after(:all) do
      Object.send(:remove_const, :KeysInteractor)
    end

    it 'returns all declared inputs, outputs, and base keys' do
      keys = KeysInteractor.allowed_context_keys
      expect(keys).to include(:input1, :input2, :output1)
      expect(keys).to include(:result, :data, :errors, :error_messages)
    end
  end
end

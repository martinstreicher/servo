# frozen_string_literal: true

RSpec.describe Servo::Callable do
  describe 'input DSL' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :name
        input :age, type: Integer

        def call
          "Hello, #{name}!"
        end
      end
    end

    it 'allows accessing declared inputs' do
      result = klass.call(age: 25, name: 'World')
      expect(result).to be_success
      expect(result.data).to eq('Hello, World!')
    end

    it 'validates type constraints when specified' do
      result = klass.call(age: 'not an integer', name: 'World')
      expect(result).to be_failure
      expect(result.errors[:age]).to include('must be a Integer')
    end

    it 'allows nil values even with type constraints' do
      result = klass.call(age: nil, name: 'World')
      expect(result).to be_success
    end
  end

  describe 'input defaults' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :ids,     default: -> { [] }
        input :manager, default: 'boss'
        input :role,    default: 'guest'

        def call
          self.result = { ids: ids, manager: manager, role: role }
        end
      end
    end

    it 'applies the default when no value is supplied', :aggregate_failures do
      result = klass.call
      expect(result).to be_success
      expect(result.role).to eq('guest')
      expect(result.manager).to eq('boss')
    end

    it 'uses the supplied value over the default' do
      result = klass.call(role: 'admin')
      expect(result).to be_success
      expect(result.role).to eq('admin')
    end

    it 'preserves an explicitly supplied nil rather than defaulting' do
      result = klass.call(manager: nil)
      expect(result).to be_success
      expect(result.manager).to be_nil
    end

    it 'invokes callable defaults fresh for each call' do
      first = klass.call
      first.ids << 'mutated'

      second = klass.call

      expect(first.ids).to eq(%w(mutated))
      expect(second.ids).to eq([])
    end

    context 'when the default is nil' do
      let(:nil_default_klass) do
        Class.new do
          Object.const_set(FactoryBot.generate(:class_name), self)
          include Servo::Callable

          input :name, default: nil

          def call
            self.result = name
          end
        end
      end

      it 'records nil as the default value' do
        result = nil_default_klass.call
        expect(result).to be_success
        expect(result.data).to be_nil
      end
    end

    context 'when a defaulted value violates a type constraint' do
      let(:typed_klass) do
        Class.new do
          Object.const_set(FactoryBot.generate(:class_name), self)
          include Servo::Callable

          input :count, default: 'not an integer', type: Integer

          def call
            count
          end
        end
      end

      it 'still enforces the type constraint on the default' do
        result = typed_klass.call
        expect(result).to be_failure
        expect(result.errors[:count]).to include('must be a Integer')
      end
    end
  end

  describe 'output DSL' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input  :multiplier
        output :computed_value

        def call
          self.computed_value = 10 * (multiplier || 1)
          computed_value
        end
      end
    end

    it 'allows setting declared outputs' do
      result = klass.call(multiplier: 5)
      expect(result).to be_success
      expect(result.computed_value).to eq(50)
    end
  end

  describe 'union types' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :date_value, type: [String, Date]

        def call
          date_value
        end
      end
    end

    it 'accepts String type' do
      result = klass.call(date_value: '2024-01-01')
      expect(result).to be_success
    end

    it 'accepts Date type' do
      result = klass.call(date_value: Date.today)
      expect(result).to be_success
    end

    it 'rejects other types' do
      result = klass.call(date_value: 12_345)
      expect(result).to be_failure
      expect(result.errors[:date_value]).to include('must be a String or Date')
    end
  end

  describe 'context restriction (default behavior)' do
    let(:restricted_klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input  :allowed_input
        output :allowed_output

        def call
          self.allowed_output = 'set'
          'done'
        end
      end
    end

    let(:unrestricted_klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        unrestrict_context!

        def call
          context.anything = 'allowed'
          'done'
        end
      end
    end

    let(:undeclared_var_klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :name

        def call
          context.undeclared_var = 'bad'
        end
      end
    end

    it 'allows setting declared inputs and outputs' do
      result = restricted_klass.call(allowed_input: 'test')
      expect(result).to be_success
      expect(result.allowed_output).to eq('set')
    end

    it 'raises error when setting undeclared context variable' do
      expect { undeclared_var_klass.call(name: 'test') }.to raise_error(
        Servo::UndeclaredContextVariableError,
        /Cannot set 'undeclared_var'/
      )
    end

    it 'allows any context variable when unrestricted' do
      result = unrestricted_klass.call
      expect(result).to be_success
      expect(result.anything).to eq('allowed')
    end
  end

  describe 'inheritance' do
    let(:parent_klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :parent_input

        def call
          parent_input
        end
      end
    end

    let(:child_klass) do
      Class.new(parent_klass) do
        Object.const_set(FactoryBot.generate(:class_name), self)

        input :child_input

        def call
          "#{parent_input} + #{child_input}"
        end
      end
    end

    it 'inherits inputs from parent class' do
      result = child_klass.call(child_input: 'child', parent_input: 'parent')
      expect(result).to be_success
      expect(result.data).to eq('parent + child')
    end
  end

  describe 'allowed_context_keys' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input  :input1
        input  :input2
        output :output1
      end
    end

    it 'returns all declared inputs, outputs, and base keys' do
      keys = klass.allowed_context_keys
      expect(keys).to include(:input1, :input2, :output1)
      expect(keys).to include(:result, :data, :errors, :error_messages)
    end
  end
end

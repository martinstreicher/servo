# frozen_string_literal: true

require 'dry-types'

module Types
  include Dry.Types()
end

RSpec.describe 'Servo::Callable dry-types integration' do
  describe 'array types' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :tags, type: Types::Array.of(Types::String)

        def call
          tags.join(', ')
        end
      end
    end

    it 'accepts valid array of strings' do
      result = klass.call(tags: %w(ruby rails))
      expect(result).to be_success
      expect(result.data).to eq('ruby, rails')
    end

    it 'rejects array with wrong element types' do
      result = klass.call(tags: [1, 2, 3])
      expect(result).to be_failure
      expect(result.errors[:tags]).to be_present
    end

    it 'rejects non-array value' do
      result = klass.call(tags: 'not an array')
      expect(result).to be_failure
      expect(result.errors[:tags]).to be_present
    end
  end

  describe 'hash schema types' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :config, type: Types::Hash.schema(
          host: Types::String,
          port: Types::Integer
        )

        def call
          "#{config[:host]}:#{config[:port]}"
        end
      end
    end

    it 'accepts valid hash with correct schema' do
      result = klass.call(config: { host: 'localhost', port: 3000 })
      expect(result).to be_success
      expect(result.data).to eq('localhost:3000')
    end

    it 'rejects hash with wrong value types' do
      result = klass.call(config: { host: 'localhost', port: 'not a number' })
      expect(result).to be_failure
      expect(result.errors[:config]).to be_present
    end
  end

  describe 'constrained types' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :name, type: Types::String.constrained(min_size: 2)
        input :age, type: Types::Integer.constrained(gteq: 0, lteq: 150)

        def call
          "#{name} is #{age} years old"
        end
      end
    end

    it 'accepts values meeting constraints' do
      result = klass.call(age: 30, name: 'John')
      expect(result).to be_success
      expect(result.data).to eq('John is 30 years old')
    end

    it 'rejects string too short' do
      result = klass.call(age: 30, name: 'J')
      expect(result).to be_failure
      expect(result.errors[:name]).to be_present
    end

    it 'rejects age out of range' do
      result = klass.call(age: 200, name: 'John')
      expect(result).to be_failure
      expect(result.errors[:age]).to be_present
    end

    it 'rejects negative age' do
      result = klass.call(age: -1, name: 'John')
      expect(result).to be_failure
      expect(result.errors[:age]).to be_present
    end
  end

  describe 'optional types' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :name, type: Types::String
        input :nickname, type: Types::String.optional

        def call
          nickname || name
        end
      end
    end

    it 'accepts nil for optional type' do
      result = klass.call(name: 'John', nickname: nil)
      expect(result).to be_success
      expect(result.data).to eq('John')
    end

    it 'accepts value for optional type' do
      result = klass.call(name: 'John', nickname: 'Johnny')
      expect(result).to be_success
      expect(result.data).to eq('Johnny')
    end
  end

  describe 'coercible types' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :count, type: Types::Coercible::Integer

        def call
          count * 2
        end
      end
    end

    it 'accepts coercible string (validates successfully)' do
      # NOTE: Servo validates types but does not coerce values.
      # The value remains a string, but dry-types Coercible considers it valid.
      result = klass.call(count: '5')
      expect(result).to be_success
    end

    it 'accepts integer directly' do
      result = klass.call(count: 5)
      expect(result).to be_success
      expect(result.data).to eq(10)
    end
  end

  describe 'mixed with plain Ruby types' do
    let(:klass) do
      Class.new do
        Object.const_set(FactoryBot.generate(:class_name), self)
        include Servo::Callable

        input :name, type: String                          # Plain Ruby class
        input :tags, type: Types::Array.of(Types::String)  # dry-types
        input :date, type: [String, Date]                  # Union type

        def call
          { date:, name:, tags: }
        end
      end
    end

    it 'validates all type specifications correctly' do
      result = klass.call(
        date: Date.today,
        name: 'Test',
        tags: %w(a b)
      )
      expect(result).to be_success
    end

    it 'fails on plain Ruby type violation' do
      result = klass.call(
        date: Date.today,
        name: 123,
        tags: %w(a b)
      )
      expect(result).to be_failure
      expect(result.errors[:name]).to be_present
    end

    it 'fails on dry-types violation' do
      result = klass.call(
        date: Date.today,
        name: 'Test',
        tags: [1, 2, 3]
      )
      expect(result).to be_failure
      expect(result.errors[:tags]).to be_present
    end

    it 'fails on union type violation' do
      result = klass.call(
        date: 12_345,
        name: 'Test',
        tags: %w(a b)
      )
      expect(result).to be_failure
      expect(result.errors[:date]).to be_present
    end
  end
end

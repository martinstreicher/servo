# frozen_string_literal: true

module Servo
  module Callable
    ##
    # Provides class-level DSL methods for declaring inputs and outputs.
    #
    # Supports three kinds of type specifications:
    #
    # 1. Plain Ruby classes: `type: String`, `type: Integer`
    # 2. Arrays of classes (union types): `type: [String, Date]`
    # 3. dry-types objects: `type: Types::Array.of(Types::String)`
    #
    # Example:
    #
    #   class MyInteractor
    #     include Servo::Callable
    #
    #     # Plain Ruby class
    #     input :name, type: String
    #
    #     # Union type
    #     input :date, type: [String, Date]
    #
    #     # dry-types (when available)
    #     input :tags, type: Types::Array.of(Types::String)
    #     input :config, type: Types::Hash.schema(host: Types::String, port: Types::Integer)
    #
    #     output :greeting
    #   end
    #
    module Dsl
      BASE_CONTEXT_KEYS = %i(data error_messages errors result).freeze

      def allowed_context_keys
        _allowed_inputs + _allowed_outputs + BASE_CONTEXT_KEYS
      end

      def input(name, type: nil)
        self._allowed_inputs = _allowed_inputs.dup.add(name)
        add_type_constraint(name, type) if type
        define_context_accessor(name)
      end

      def output(name, type: nil)
        self._allowed_outputs = _allowed_outputs.dup.add(name)
        add_type_constraint(name, type) if type
        define_context_accessor(name)
        define_context_writer(name)
      end

      def restrict_context?
        _restrict_context
      end

      def unrestrict_context!
        self._restrict_context = false
      end

      private

      def add_type_constraint(name, type)
        self._type_constraints = _type_constraints.merge(name => type)

        validate do
          value = context.public_send(name)
          valid, error_message = TypeChecker.validate(value, type)

          errors.add(name, error_message) unless valid
        end
      end

      def define_context_accessor(name)
        return if method_defined?(name)

        define_method(name) { context.public_send(name) }
      end

      def define_context_writer(name)
        define_method("#{name}=") { |value| context.public_send("#{name}=", value) }
      end
    end
  end
end

# frozen_string_literal: true

module Servo
  module Callable
    ##
    # Provides type checking functionality with support for dry-types.
    #
    # Supports three kinds of type specifications:
    #
    # 1. Plain Ruby classes: `type: String`, `type: Integer`
    # 2. Arrays of classes (union types): `type: [String, Date]`
    # 3. dry-types objects: `type: Types::Array.of(Types::String)`
    #
    # When dry-types is available, it provides richer type checking including:
    # - Constrained types: `Types::String.constrained(min_size: 1)`
    # - Array types: `Types::Array.of(Types::Integer)`
    # - Hash schemas: `Types::Hash.schema(name: Types::String)`
    # - Optional types: `Types::String.optional`
    # - Coercions: `Types::Coercible::Integer`
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
    #   end
    #
    module TypeChecker
      class << self
        # Check if the given type specification is a dry-types type
        def dry_type?(type)
          return false unless dry_types_available?

          type.is_a?(Dry::Types::Type) ||
            type.is_a?(Dry::Types::Constrained) ||
            (type.respond_to?(:primitive) && type.respond_to?(:call))
        end

        def dry_types_available? = defined?(Dry::Types)

        # Build a human-readable type description for error messages
        def type_description(type)
          return type.to_s if dry_type?(type)
          return type.map(&:name).join(' or ') if type.is_a?(Array)

          type.name
        end

        # Validate a value against a type specification
        # Returns [valid?, error_message]
        def validate(value, type)
          return [true, nil] if value.nil?
          return validate_with_dry_types(value, type) if dry_type?(type)
          return validate_union_type(value, type) if type.is_a?(Array)

          validate_ruby_class(value, type)
        end

        private

        def validate_ruby_class(value, type)
          return [true, nil] if value.is_a?(type)

          [false, "must be a #{type_description(type)}"]
        end

        def validate_union_type(value, types)
          return [true, nil] if types.any? { |t| value.is_a?(t) }

          [false, "must be a #{type_description(types)}"]
        end

        def validate_with_dry_types(value, type)
          result = type.try(value)
          return [true, nil] if result.success?

          [false, "must be a #{type_description(type)}"]
        rescue Dry::Types::CoercionError => e
          [false, "must be a #{type_description(type)} (#{e.message})"]
        end
      end
    end
  end
end

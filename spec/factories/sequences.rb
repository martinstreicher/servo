# frozen_string_literal: true

FactoryBot.define do
  sequence(:class_name) { |n| "AnonymousClass#{n}" }
end

# frozen_string_literal: true

class Crank
  include Servo::Callable

  def call
    context.result = true
    false
  end
end

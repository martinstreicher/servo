# frozen_string_literal: true

class Crank
  include Servo::Callable

  def perform
    context.result = true
    false
  end
end

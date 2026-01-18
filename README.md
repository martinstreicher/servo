# Servo

A Ruby gem for building service objects (interactors) with validations, type checking, memoization, and background job support.

Servo builds on the [interactor](https://github.com/collectiveidea/interactor) gem, adding:

- **Input/Output DSL** - Declare allowed context variables with optional type constraints
- **Context Restriction** - Prevent accidental assignment of undeclared variables (enabled by default)
- **Type Checking** - Validate inputs with Ruby classes, union types, or dry-types
- **ActiveModel Validations** - Full validation support with error messages
- **Callbacks** - Before, after, and around callbacks for the perform method
- **Memoization** - Built-in memoization via MemoWise
- **Background Jobs** - Run interactors asynchronously with ActiveJob or Sidekiq

## Installation

Add to your Gemfile:

```ruby
gem 'servo'
```

For enhanced type checking with dry-types (optional):

```ruby
gem 'servo'
gem 'dry-types'
```

Then run:

```bash
bundle install
```

## Quick Start

```ruby
class CreateUser
  include Servo::Callable

  input  :email, type: String
  input  :name,  type: String
  output :user

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name,  presence: true

  def perform
    self.user = User.create!(email: email, name: name)
    user
  end
end

# Call the interactor
result = CreateUser.call(email: 'alice@example.com', name: 'Alice')

result.success?  # => true
result.user      # => #<User id: 1, email: "alice@example.com", name: "Alice">
result.data      # => #<User ...> (same as return value of perform)

# With invalid input
result = CreateUser.call(email: '', name: 'Bob')

result.failure?        # => true
result.errors          # => #<ActiveModel::Errors ...>
result.error_messages  # => ["Email can't be blank", "Email is invalid"]
```

## Declaring Inputs and Outputs

Use `input` to declare expected parameters and `output` to declare values your interactor will produce:

```ruby
class ProcessOrder
  include Servo::Callable

  input  :order_id
  input  :user
  output :receipt
  output :confirmation_number

  def perform
    order = Order.find(order_id)
    self.receipt = generate_receipt(order)
    self.confirmation_number = SecureRandom.hex(8)
    receipt
  end
end
```

### Context Restriction (Default Behavior)

By default, Servo restricts context to only declared inputs and outputs. Attempting to set an undeclared variable raises an error:

```ruby
class MyInteractor
  include Servo::Callable

  input :name

  def perform
    context.undeclared = 'value'  # Raises Servo::UndeclaredContextVariableError!
  end
end
```

To disable restriction (not recommended):

```ruby
class LegacyInteractor
  include Servo::Callable

  unrestrict_context!

  def perform
    context.anything = 'allowed'  # No error
  end
end
```

## Type Checking

### Basic Ruby Types

```ruby
class Greet
  include Servo::Callable

  input :name,  type: String
  input :count, type: Integer

  def perform
    "Hello, #{name}!" * count
  end
end

Greet.call(name: 'World', count: 3)       # Success
Greet.call(name: 123, count: 3)           # Failure: "Name must be a String"
```

### Union Types

Accept multiple types using an array:

```ruby
class ParseDate
  include Servo::Callable

  input :date, type: [String, Date, Time]

  def perform
    case date
    when String then Date.parse(date)
    when Time   then date.to_date
    else date
    end
  end
end
```

### dry-types Integration

For advanced type checking, add `dry-types` to your Gemfile:

```ruby
class CreateProduct
  include Servo::Callable

  # Define types
  Types = Dry.Types()

  input :name,  type: Types::String.constrained(min_size: 1)
  input :price, type: Types::Coercible::Float.constrained(gt: 0)
  input :tags,  type: Types::Array.of(Types::String)

  def perform
    Product.create!(name: name, price: price, tags: tags)
  end
end
```

Supported dry-types features:

- Constrained types: `Types::String.constrained(min_size: 1)`
- Array types: `Types::Array.of(Types::Integer)`
- Hash schemas: `Types::Hash.schema(name: Types::String)`
- Optional types: `Types::String.optional`
- Coercible types: `Types::Coercible::Integer`

## Validations

Servo includes ActiveModel::Validations for full validation support:

```ruby
class TransferFunds
  include Servo::Callable

  input :from_account
  input :to_account
  input :amount

  validates :from_account, :to_account, presence: true
  validates :amount, numericality: { greater_than: 0 }

  validate :sufficient_balance

  def perform
    from_account.withdraw(amount)
    to_account.deposit(amount)
  end

  private

  def sufficient_balance
    return if from_account.nil?

    if from_account.balance < amount
      errors.add(:amount, 'exceeds available balance')
    end
  end
end
```

## Callbacks

Use ActiveSupport callbacks to run code before, after, or around `perform`:

```ruby
class AuditedOperation
  include Servo::Callable

  input  :user
  input  :action
  output :audit_log

  set_callback :perform, :before, :start_audit
  set_callback :perform, :after,  :complete_audit
  set_callback :perform, :around, :measure_duration

  def perform
    # Main logic here
    execute_action
  end

  private

  def start_audit
    self.audit_log = []
    audit_log << "Started: #{action}"
  end

  def complete_audit
    audit_log << "Completed: #{action}"
    AuditLog.create!(entries: audit_log)
  end

  def measure_duration
    start = Time.current
    yield
    audit_log << "Duration: #{Time.current - start}s"
  end
end
```

## Memoization

Servo includes MemoWise for easy memoization:

```ruby
class ExpensiveCalculation
  include Servo::Callable

  input :data

  memo_wise def processed_data
    # This expensive operation only runs once
    data.map { |item| complex_transform(item) }
  end

  def perform
    processed_data.sum
  end
end
```

## Background Jobs

### Using call_later

Run any interactor asynchronously:

```ruby
class SendWelcomeEmail
  include Servo::Callable

  input :user_id

  def perform
    user = User.find(user_id)
    UserMailer.welcome(user).deliver_now
  end
end

# Enqueue for background processing
SendWelcomeEmail.call_later(interactor_args: { user_id: 123 })

# With job options
SendWelcomeEmail.call_later(
  interactor_args: { user_id: 123 },
  job_args: { queue: 'mailers', wait: 5.minutes }
)
```

### ActiveJob Integration

Create job classes that include Callable:

```ruby
class ProcessPaymentJob < Servo::Jobs::ActiveJob
  input :order_id
  input :amount

  validates :order_id, :amount, presence: true

  def perform
    order = Order.find(order_id)
    PaymentGateway.charge(order, amount)
  end
end

# Enqueue
ProcessPaymentJob.perform_later(order_id: 123, amount: 99.99)

# Run synchronously (returns interactor context)
result = ProcessPaymentJob.perform_now(order_id: 123, amount: 99.99)
result.success?
```

### Sidekiq Integration

```ruby
class ImportDataJob < Servo::Jobs::SidekiqJob
  input :file_path

  def perform
    CSV.foreach(file_path) do |row|
      Record.create!(row.to_h)
    end
  end
end

# Enqueue
ImportDataJob.perform_async(file_path: '/path/to/data.csv')
```

## Controller Integration

Servo includes a concern for Rails controllers:

```ruby
class Api::UsersController < ApplicationController
  include Servo::Controllers::Concerns::Reply

  def create
    result = CreateUser.call(user_params)

    reply(
      condition: result.success?,
      record:    result.user,
      errors:    result.errors,
      success:   :created,
      failure:   :unprocessable_entity
    )
  end

  private

  def user_params
    params.require(:user).permit(:email, :name)
  end
end
```

## Error Handling

```ruby
result = CreateUser.call(email: 'invalid')

if result.failure?
  # Access errors
  result.errors                    # ActiveModel::Errors object
  result.errors[:email]            # ["can't be blank", "is invalid"]
  result.error_messages            # ["Email can't be blank", "Email is invalid"]
  result.errors.full_messages      # Same as error_messages
end
```

## Inheritance

Interactors can inherit from other interactors:

```ruby
class BaseInteractor
  include Servo::Callable

  input :current_user

  validates :current_user, presence: true
end

class CreatePost < BaseInteractor
  input  :title
  input  :body
  output :post

  validates :title, presence: true

  def perform
    self.post = current_user.posts.create!(title: title, body: body)
  end
end
```

## Development

```bash
# Install dependencies
bundle install

# Run tests
bundle exec rspec

# Run linter
bundle exec rubocop
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

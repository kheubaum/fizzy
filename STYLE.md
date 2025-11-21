
# Style

We aim to write code that is a pleasure to read, and we have a lot of opinions about how to do it well. Writing great code is an essential part of our programming culture, and we deliberately set a high bar for every code change anyone contributes. We care about how code reads, how code looks, and how code makes you feel when you read it.

We love discussing code. If you have questions about how to write something, or if you detect some smell you are not quite sure how to solve, please ask away to other programmers. A Pull Request is a great way to do this.

When writing new code, unless you are very familiar with our approach, try to find similar code elsewhere to look for inspiration.

## Conditional returns

In general, we prefer to use expanded conditionals over guard clauses.

```ruby
# Bad
def todos_for_new_group
  ids = params.require(:todolist)[:todo_ids]
  return [] unless ids
  @bucket.recordings.todos.find(ids.split(","))
end

# Good
def todos_for_new_group
  if ids = params.require(:todolist)[:todo_ids]
    @bucket.recordings.todos.find(ids.split(","))
  else
    []
  end
end
```

This is because guard clauses can be hard to read, especially when they are nested.

As an exception, we sometimes use guard clauses to return early from a method:

* When the return is right at the beginning of the method.
* When the main method body is not trivial and involves several lines of code.

```ruby
def after_recorded_as_commit(recording)
  return if recording.parent.was_created?

  if recording.was_created?
    broadcast_new_column(recording)
  else
    broadcast_column_change(recording)
  end
end
```

## Methods ordering

We order methods in classes in the following order:

1. `class` methods
2. `public` methods with `initialize` at the top.
3. `private` methods

## Invocation order

We order methods vertically based on their invocation order. This helps us to understand the flow of the code.

```ruby
class SomeClass
  def some_method
    method_1
    method_2
  end

  private
    def method_1
      method_1_1
      method_1_2
    end
  
    def method_1_1
      # ...
    end
  
    def method_1_2
      # ...
    end
  
    def method_2
      method_2_1
      method_2_2
    end
  
    def method_2_1
      # ...
    end
  
    def method_2_2
      # ...
    end
end
```

## To bang or not to bang

Should I call a method `do_something` or `do_something!`?

As a general rule, we only use `!` for methods that have a correspondent counterpart without `!`. In particular, we don’t use `!` to flag destructive actions. There are plenty of destructive methods in Ruby and Rails that do not end with `!`.

## Visibility modifiers

We don't add a newline under visibility modifiers, and we indent the content under them.

```ruby
class SomeClass
  def some_method
    # ...
  end

  private
    def some_private_method_1
      # ...
    end

    def some_private_method_2
      # ...
    end
end
```

If a module only has private methods, we mark it `private` at the top and add an extra new line after but don't indent.

```ruby
class SomeModule
  private
  
  def some_private_method
    # ...
  end
end
```

## CRUD operations from controllers

In general, we favor a vanilla Rails approach to CRUD operations. We create and update models from Rails controllers passing the parameters directly to the model constructor or update method. We do not use services or form objects to handle these operations.

There are exceptional scenarios where we need to perform more complex operations, and we use form objects or higher-level service methods to handle them. We use the same pattern for both creations and updates.

Related to this, we prefer to avoid [nested attributes](https://api.rubyonrails.org/classes/ActiveRecord/NestedAttributes/ClassMethods.html). If you find yourself wanting to use `accepts_nested_attributes_for`, that's a good smell that you might want to consider using a form object instead. 

As an example, you can check how we create and update messages in HEY's: `MessagesController`:

```ruby
class MessagesController < ApplicationController
  def create
    @entry = Entry.enter \
      new_message,
      on: new_topic,
      status: :drafted,
      address: entry_addressed_param,
      scheduled_delivery_at: entry_scheduled_delivery_at_param,
      scheduled_bubble_up_on: entry_scheduled_bubble_up_on_param

    respond_to_saved_entry @entry
  end

  def update
    previously_scheduled = @entry.scheduled_delivery

    @entry.revise \
      message_params,
      status: :drafted,
      is_delivery_imminent: !entry_status_param.drafted?,
      address: entry_addressed_param,
      scheduled_delivery_at: entry_scheduled_delivery_at_param,
      scheduled_bubble_up_on: entry_scheduled_bubble_up_on_param

    respond_to_saved_entry(@entry, previously_scheduled: previously_scheduled)
  end
end

class Entry < ApplicationRecord
  def self.enter(*args, **kwargs)
    Entry::Enter.new(*args, **kwargs).perform
  end

  def revise(*args, **kwargs)
    Entry::Revise.new(self, *args, **kwargs).perform
  end
end
```

## Run async operations in jobs

As a general rule, we write shallow job classes that delegate the logic itself to domain models:

* We typically use the suffix `_later` to flag methods that enqueue a job.
* A common scenario is having a model class that enqueues a job that, when executed, invokes some method in that same class. In this case, we use the suffix `_now` for the regular synchronous method.

```ruby
module Event::Relaying
  extend ActiveSupport::Concern

  included do
    after_create_commit :relay_later
  end

  def relay_later
    Event::RelayJob.perform_later(self)
  end

  def relay_now
    # ...
  end
end

class Event::RelayJob < ApplicationJob
  def perform(event)
    event.relay_now
  end
end
```

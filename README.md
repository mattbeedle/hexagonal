# Hexagonal

A simple gem to provide structure and guidance for writing hexagonal ruby
applications.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'hexagonal'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install hexagonal

## Why?!?!

Rails applications are usually really fast to build at the beginning, but due to
high coupling, as they mature they begin to calcify. Eventually adding any new
features and fixing bugs becomes a pain. Developers get caught in callback hell.
Nothing can be tested in isolation. Test suites take >10 minutes to run. This is
also sometimes true of non-Rails Ruby apps. Some people will suggest that Rails
Engines are a better solution for breaking up complexity. I say that engines and
Hexagonal can be used together. Engines don't solve the problem of domain
objects being tightly coupled to the database and often to each other through
callbacks for example.

Hexagonal is an abstraction of the way that I've been building my latest Ruby
applications. It's inspired by [Matt Wynne](http://www.confreaks.com/videos/977-goruco2012-hexagonal-rails),
[Brandur](https://brandur.org/mediator), [grouper](http://eng.joingrouper.com/blog/2014/03/03/rails-the-missing-parts-interactors),
[agileplanner](https://www.agileplannerapp.com/blog/building-agile-planner/refactoring-with-hexagonal-rails),
[Victor Savkins](http://victorsavkin.com/post/42542190528/hexagonal-architecture-for-rails-developers)
and many discussions with [@soulim](https://github.com/soulim).
Hexagonal provides base classes for everything required to build a small
modular, Ruby application. See Structure section below.

## Usage

When using Rails, the following generators are available. When not using Rails,
please see the examples folder for how to extend the provided classes
correctly.

### Generate a resource
This will generate a repository, policy, mediators and runners for all CRUD
actions for a specified resource.
```
rails generate hexagonal:resource [RESOURCE_NAME]
```

### Generate a repository
```
rails generate hexagonal:repository [REPOSITORY_NAME]
```

### Generate a runner
```
rails generate hexagonal:runner [RUNNER_NAME]
```

### Generate a mediator
```
rails generate hexagonal:mediator [MEDIATOR_NAME]
```

### Generate a policy
```
rails generate hexaganal:policy [POLICY_NAME]
```

### Generate a worker
```
rails generate hexagonal:worker [WORKER_NAME]
```

### Generate a job
```
rails generate hexagonal:job [JOB_NAME]
```

### Generate a decorator
```
rails generate hexagonal:decorator [MODEL_NAME]
```

## Structure

Here is the basic app structure along with some implementation examples.
Not all of these objects need to inherited/extended from Hexagonal. Services,
Jobs and Workers are not planned to be part of the gem.

### Runners (app/runners)
These are my own creation. They are responsible for model materialization,
authorization (authentication still happens in the controller) and running
 parameter validation

```ruby
class CreateJobRunner < Hexagonal::Runners::CreateRunner
  private

  def form
    @form ||= JobForm.new(attributes)
  end

  def mediator
    @mediator ||= CreateJobMediator.new(user, form.attributes)
  end
end
```

### Mediators (app/mediators)
A [Mediator](http://en.wikipedia.org/wiki/Mediator_pattern) is a design
pattern encapsulating how a set of objects interact
The mediators take care of saving/updating/deleting/etc and calling out
to workers (for longer jobs, like looking up social media data)
or jobs (for shorter jobs, like sending email)

```ruby
class CreateJobMediator < Hexagonal::Mediators::CreateMediator
  def target
    @target ||= Job.new(attributes)
  end

  private

  def default_attributes
    { created_by_id: user.id, account_id: user.account_id }
  end

  def repository
    @repository ||= JobRepository.new
  end
end
```

### Forms (app/forms)
These contain parameter validation logic.

```ruby
class JobForm
  include Hexagonal::Form

  attribute :title, String
  attribute :remote_working_allowed, Boolean, default: true

  validates :title, presence: true
end
```

### Decorators (app/decorators)
These are used to add an object-oriented presentation layer. Decorators use the
[draper gem](https://github.com/drapergem/draper).

```ruby
class JobDecorator < Draper::Decorator
  decorates :job

  delegate_all

  def address
    [street, city, country].compact.join(', ')
  end
end
```

### Workers (app/workers)
Sidekiq workers to handle longer running tasks (to avoid slow requests).
The workers themselves have barely any code inside. They just materialize any
models required and then call the required service.

```ruby
class ContactImportWorker
  include Sidekiq::Worker

  def perform(user_id)
    User.find(user_id).tap do |user|
      ContactImportService.new(user).call
    end
  end
end
```

### Jobs (app/jobs)
Sucker Punch jobs. Sucker punch handles background tasks in a single process
using asynchronous Ruby. It's good for keeping costs down on heroku.
I find sidekiq to [generally be overkill](http://brandonhilkert.com/blog/why-i-wrote-the-sucker-punch-gem/)
for most tasks (email sending for example). Sucker Punch workers are the same as
Sidekiq workers. Just materialize models and call the correct service

```ruby
class SignupConfirmationJob
  include SuckerPunch::Job

  def perform(user)
    UserMailer.signup_confirmation(user).deliver
  end
end
```

### Services (app/services)
When the app needs to interact with any third party service then a service
object is used. They are called either from workers or mediators. They handle
the details of things like email sending, lookup up social media data,
importing/syncing contacts, polling IMAP, etc.

```ruby
class ContactImportService
  def initialize(user)
    @user = user
  end

  def call
    # some complex logic to pull contacts from social media
  end
end
```

### Responses (app/responses)
These handle responding to the client. They are almost all just simple
delegators that help me to avoid duplicating code in controllers.

```ruby
class CreateResponse < SimpleDelegator
  def created_successfully(object)
    respond_with object
  end

  def creation_failed(object)
    render :errors, object.errors.as_json
  end
end
```

### Repositories (app/repositories)
Used to access the database. I'm trying to gradually decouple the app completely
from ActiveRecord. It keeps the queries private instead of leaking storage API
details into the app.

```ruby
class JobRepository
  include Hexagonal::Repository

  def find_by_creator_id(creator_id)
    adapter.where(creator_id: creator_id)
  end
end
```

### Adapters (app/adapters)
Adapters communicate between specific storage implementations and repositories.
So far there is only an ActiveRecordAdapter. When I comes time to switch to
something else, perhaps sequel, then I will just need to define a new adapter
and plug it into the base repository. Adapters also need to define a Unit Of
Work in order to be able to roll back groups of changes. With SQL this is just a
wrapper around a Transaction.

### Errors (app/errors)
These define business specific errors rather than just using the standard ones.
Also map database specific errors to business ones so that the database can be
switched out easily.

### Policies (app/policies)
These handle authorization.

```ruby
class JobPolicy
  def initialize(user, job)
    @user = user
    @job = job
  end

  def delete?
    job.created_by == user
  end

  private

  attr_reader :user, :job
end
```

## Example

Here is an example Rails API controller using hexagonal
```ruby
class JobsController < ApplicationController::Base
  before_filter :authenticate_user!

  def index
    filter_runner.run
  end

  def show
    find_runner.run
  end

  def create
    create_runner.run
  end

  def update
    update_runner.run
  end

  def destroy
    delete_runner.run
  end

  private

  def find_runner
    FindJobRunner.new(find_one_response, current_user, params[:id])
  end

  def find_one_response
    FindOneResponse.new(self)
  end

  def filter_runner
    FilterJobsRunner.new(find_all_response, current_user, params)
  end

  def create_runner
    CreateJobRunner.new(create_response, current_user, params[:job])
  end

  def create_response
    CreateResponse.new(self)
  end

  def update_runner
    UpdateJobRunner
      .new(update_response, current_user, params[:id], params[:job])
  end

  def update_response
    UpdateResponse.new(self)
  end

  def delete_runner
    DeleteRunner.new(delete_response, current_user, params[:id])
  end

  def delete_response
    DeleteResponse.new(self)
  end
end
```

## Supported Rubies
2.0.x, 2.1.x, JRuby 1.7.x

## Contributing

1. Fork it ( https://github.com/[my-github-username]/hexagonal/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Alternatives
- [hexx](https://github.com/nepalez/hexx)

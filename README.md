# OpeNER Daemons

This Gem makes it possible for OpeNER components to be used as a daemon using
Amazon SQS and Amazon S3. SQS is used for job input while S3 is used for storing
results. Daemons only take URLs as input, they don't allow text to be specified
directly due to size restrictions of SQS (a maximum of 256 KB).

## Usage

Create an executable file `bin/<component>-daemon`, for example
`bin/language-identifier-daemon`, with the following content:

    #!/usr/bin/env ruby
    require 'opener/daemons'

    controller = Opener::Daemons::Controller.new(
      :name      => 'opener-<component>',
      :exec_path => File.expand_path('../../exec/<component>.rb', __FILE__)
    )

    controller.run

Replace `<component>` with the name of the component. For example, for the
language identifier this would result in the following:

    #!/usr/bin/env ruby
    require 'opener/daemons'

    controller = Opener::Daemons::Controller.new(
      :name      => 'opener-language-identifier',
      :exec_path => File.expand_path('../../exec/language-identifier.rb', __FILE__)
    )

    controller.run

Next, create an executable file `exec/<component>.rb`, for example
`exec/language-identifier.rb`, with the following content:

    #!/usr/bin/env ruby
    require 'opener/daemons'

    require_relative '../lib/opener/<component>'

    daemon = Opener::Daemons::Daemon.new(Opener::<constant>)

    daemon.start

Replace `<component>` with the component name, replace `<constant>` with the
corresponding constant. For example, for the language identifier:


    #!/usr/bin/env ruby
    require 'opener/daemons'

    require_relative '../lib/opener/language_identifier'

    daemon = Opener::Daemons::Daemon.new(Opener::LanguageIdentifier)

    daemon.start

If the component takes extra arguments, such as a resource path, these should be
set in the `initialize` method of the component using the actual environment
variables.

## Requirements

* A supported Ruby version (see below)
* Amazon SQS
* Amazon S3

The following Ruby versions are supported:

| Ruby     | Required      | Recommended |
|:---------|:--------------|:------------|
| MRI      | >= 1.9.3      | >= 2.1.4    |
| Rubinius | >= 2.2        | >= 2.3.0    |
| JRuby    | >= 1.7        | >= 1.7.16   |

## Installation

Install it from RubyGems:

    gem install opener-daemons

Or using Bundler:

    # add this to your Gemfile
    gem 'opener-daemons'

    # then run this
    bundle install

## Job Format

Jobs should be serialized as JSON and should adhere to the JSON schema
definition [schema/sqs_input.json](schema/sqs_input.json). In short, a job is a
JSON object with the following fields:

* `input_url`: the input URL
* `callbacks`: an array of URLs
* `identifier`: a unique identifier to use for the file stored in S3, if no
  value is given an identifier will be generated automatically
* `metadata`: an object containing arbitrary metadata, will be passed to every
  callback URL

An example:

    {
        "input_url": "http://example.com/my-kaf.xml",
        "callbacks": ["http://example.com/my-callback"],
        "identifier": "foo123",
        "metadata": {
            "customer_id": 123
        }
    }

For more specific details see the schema.

## Output

Daemon output is stored in an Amazon S3 bucket, output files are named
`<identifier>.xml` where `<identifier>` is the unique identifier of the
document. The content type of these documents is set to `application/xml`.
Metadata associated with the job (as specified in the `metadata` field) is saved
as metadata of the S3 object.

Callback URLs will receive the URL of an uploaded document, _not_ the actual
content itself. The S3 URLs are only valid for a limited time (currently 1 hour)
so callbacks must ensure they can process the input within that time limit.

## Monitoring

Components using this Gem can measure performance using New Relic and report
errors using Rollbar. To support this the following two environment variables
must be set:

* `NEWRELIC_TOKEN`
* `ROLLBAR_TOKEN`

For New Relic the application names will be `opener-<component>` where
`<component>` is the component name, as defined by a component itself. If one of
these environment variables is not set the corresponding feature is disabled.

## CLI Options

Each daemon takes a set of options that can be used to configure the input
queue, the S3 bucket and so forth. For an up to date list of these options and
their descriptions run a daemon using the `--help` option.

Some of these options set environment variables that can be used by components,
these are as following:

* `input`: sets the input queue in the `INPUT_QUEUE` variable
* `threads`: sets the amount of threads to use in the `DAEMON_THREADS` variable
* `bucket`: sets the S3 bucket to use for output documents in the
  `OUTPUT_BUCKET` variable

## Amazon Environment Variables

To properly configure the daemons for Amazon you should set the following
environment variables:

* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`
* `AWS_REGION`

If you're running this daemon on an EC2 instance then the first two environment
variables will be set automatically if the instance has an associated IAM
profile. The `AWS_REGION` variable must _always_ be set.

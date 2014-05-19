# Opener::Daemons

This GEM is part of the OpeNER project, which is the NLP toolchain for the rest
of us. This particular GEM makes is possible that al OpeNER components can
actually be launched as deamons reading from and push to Amazon SQS queues.

## Installation

Add this line to your application's Gemfile:

    gem 'opener-daemons'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install opener-daemons


## SQS

The Opener-daemon GEM uses Amazon SQS service as a message service. In order for
this to work properly you need an Amazon AWS account and you need to set the
following 3 environment variables in your shell:

```
export AWS_ACCESS_KEY_ID='...'
export AWS_SECRET_ACCESS_KEY='...'
export AWS_REGION='...' #e.g. eu-west-1
```

To see how you specify which queues to use, checkout the usage section below.

## Implementation

This Gem is intended for use with other OpeNER components. In order to turn a
component in to a Daemon you have to do the following:

Add the opener-daemons gem to the gemspec of your component (or the the Gemfile
if your component is not a gem).

```
  gem.add_dependency 'opener-daemons'
```

Create a file in the bin/ directory of the component. Following the OpeNER
naming conventions that will be something like this (e.g. the
language-identifier). This file provides you with the option to launch a daemon
from the command line.

    touch bin/language-identifier-daemon

Then add the following lines and replace the language-identifier with your own
component:

```ruby
#!/usr/bin/env ruby
require 'rubygems'
require 'opener/daemons'

exec_path = File.expand_path("exec/language-identifier.rb")
Opener::Daemons::Controller.new(:name=>"language-identifier",
                                :exec_path=>exec_path)
```

After that you have to create a file that does the actual work in an "exec"
directory. From the root of your component do this:

```
mkdir exec
touch exec/language-identifier.rb
```

Then copy paste the following code into that file, replacing the
"language-identifier" parts with your own component.

```ruby
require 'opener/daemons'
require 'opener/language_identifier'

options = Opener::OptParser.parse!(ARGV)
daemon = Opener::Daemon.new(Opener::LanguageIdentifier, options)
daemon.start
```

Now you should be able to launch yourself a LanguageIdentifier daemon. Check out
the exact usage of the daemon by typing:

```
bin/language-identifier-daemon -h
```

## Usage

Once you implemented the daemon you can use the -h option to get usage
information. It will look like this, with the "language-identifier" strings
replaced by your own component.

```
Usage: language-identifier.rb <start|stop|restart> [options]

Specific options:
    -i, --input INPUT_QUEUE_NAME     Input queue name
    -o, --output OUTPUT_QUEUE_NAME   Output queue name
    -b, --batch-size BATCH_SIZE      Request x messages at once where x is between 1 and 10
    -w, --workers NUMBER             number of worker thread
    -r, --readers NUMBER             number of reader threads
    -p, --writers NUMBER             number of writer / pusher threads
        --log FILENAME               Filename and path of logfile. Defaults to STDOUT
        --pid FILENAME               Filename and path of pidfile. Defaults to /var/run/{filename}.rb
        --pidpath DIRNAME            Directory where to put the PID file. Is Overwritten by --pid if that option is present
        --debug                      Turn on debug log level

Common options:
    -h, --help                       Show this message
```


## Contributing

1. Fork it ( http://github.com/opener-project/opener-daemons/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

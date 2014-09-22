require "opener/daemons/version"
require "opener/daemons/sqs"
require "opener/daemons/s3"
require "opener/daemons/daemon"
require "opener/daemons/opt_parser"
require "opener/daemons/controller"
require 'opener/callback_handler'

require "dotenv"
env_file = File.expand_path("~/.opener-daemons-env")
Dotenv.load(env_file)

module Opener
  module Daemons
  end
end

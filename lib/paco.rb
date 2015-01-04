require "paco/version"
require "paco/specification"
require "paco/repository"
require "paco/env"

module Paco
  class Config
    include Singleton

    attr_accessor :repos, :env, :dependencies
  end

  def env(envname)
    Config.instance.env = Paco::Env::Unity.new
  end

  def paco(*args)
    Config.instance.dependencies = [] unless Config.instance.dependencies
    Config.instance.dependencies.push args
  end

  def source(*args)
    repos = args.shift
    Config.instance.repos = \
      Repository::GoogleDrive.new(repos[:email], repos[:pem], repos[:collection_url])
  end

  module_function :paco, :source, :env
end

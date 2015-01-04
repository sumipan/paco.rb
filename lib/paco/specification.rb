
module Paco
  class Specification
    attr_accessor :name, :version, :authors, :email, :summary, :homepage, :files, :dependencies

    def initialize
      @dependencies = []

      yield self
    end

    def path
      sprintf('%s-%s',name, version)
    end

    def add_dependency(name, version=nil)
      @dependencies.push({
        :name => name,
        :version => version,
      })
    end
  end
end

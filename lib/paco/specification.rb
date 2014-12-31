
module Paco
  class Specification
    attr_accessor :name, :version, :authors, :email, :summary, :homepage, :files

    def initialize
      yield self
    end

    def path
      sprintf('%s-%s',name, version)
    end
  end
end

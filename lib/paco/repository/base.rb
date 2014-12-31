
module Paco
  module Repository
    class Base
      def get(name, version=nil)
        raise 'error. must override.'
      end
    end
  end
end

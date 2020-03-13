module Marten
  module Routing
    module Parameter
      abstract class Base
        abstract def regex : Regex
        abstract def loads(value : ::String)
        abstract def dumps(value) : ::String
      end
    end
  end
end

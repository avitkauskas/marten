module Marten
  abstract class Schema
    module Field
      # Represents a boolean schema field.
      class Bool < Base
        def deserialize(value) : ::Bool
          [true, "true", 1, "1", "yes", "on"].includes?(value)
        end

        def serialize(value) : ::String?
          value.try(&.to_s)
        end

        private def empty_value?(value) : ::Bool
          !value
        end
      end
    end
  end
end
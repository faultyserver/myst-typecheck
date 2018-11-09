module Myst
  module TypeCheck
    class TypeError < Exception
      def initialize(node : Node)
        @message = <<-MESSAGE
          Type checking failed:

            #{Myst::Printer.print(node)}

        MESSAGE
      end
    end

    class ReturnTypeMismatchError < TypeError
      def initialize(expected_type : Type, actual_type : Type)
        @message = <<-MESSAGE
          Expected Call to return `#{expected_type}` but resulted in `#{actual_type}`.
        MESSAGE
      end
    end
  end
end

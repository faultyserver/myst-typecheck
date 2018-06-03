module Myst
  module TypeCheck
    class TypeError < Exception
      property node : Node

      def initialize(@node : Node)
        @message = <<-MESSAGE
          Type checking failed:

            #{Myst::Printer.print(node)}

        MESSAGE
      end
    end
  end
end

module Push
  module Daemon
    class C2dm
      attr_accessor :configuration
      def initialize(options)
        self.configuration = options
      end

      def pushconnections
        self.configuration[:connections]
      end

      def totalconnections
        pushconnections
      end

      def connectiontype
        C2dmSupport::ConnectionC2dm
      end

      def stop; end
    end
  end
end
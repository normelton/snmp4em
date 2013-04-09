module SNMP

  class Null  # @private
    class << self
      def rubify
        nil
      end
    end
  end

end

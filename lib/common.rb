module SNMP #:nodoc:
  class Null #:nodoc:
    class << self
      def rubify
        nil
      end
    end
  end
  
  class OctetString #:nodoc:
    alias :rubify :to_s
  end
  
  class Integer #:nodoc:
    alias :rubify :to_i
  end
  
  class ObjectId #:nodoc:
    alias :rubify :to_s
  end
  
  class IpAddress #:nodoc:
    alias :rubify :to_s
  end
  
  class ResponseError
    attr_reader :error_status
    alias :rubify :error_status #:nodoc:
    
    def initialize(error_status) #:nodoc:
      @error_status = error_status
    end
    
    # String representation of this error
    def to_s
      @error_status.to_s
    end
  end
end
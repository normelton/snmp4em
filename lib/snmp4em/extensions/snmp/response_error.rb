module SNMP #:nodoc:

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

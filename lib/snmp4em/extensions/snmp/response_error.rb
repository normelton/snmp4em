module SNMP #:nodoc:

  class ResponseError
    attr_reader :error_status
    alias :rubify :error_status #:nodoc:
    
    def initialize(error) #:nodoc:
      if [SNMP::EndOfMibView, SNMP::NoSuchObject, SNMP::NoSuchInstance].include? error
        @error_status = error.asn1_type.to_sym
      else
        @error_status = error.to_sym
      end
    end
    
    # String representation of this error
    def to_s
      @error_status.to_s
    end
  end

end

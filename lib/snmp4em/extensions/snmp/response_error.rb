module SNMP

  class ResponseError
    attr_reader :error_status
    alias :rubify :error_status
    
    # Accepts either a string (from SNMP::PDU.error_status) or one of SNMP::EndOfMibView, SNMP::NoSuchObject, or SNMP::NoSuchInstance
    def initialize(error)
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

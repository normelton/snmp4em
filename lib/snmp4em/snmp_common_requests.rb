# The SNMP4EM library 

module SNMP4EM
  module SNMPCommonRequests
    # Sends an SNMP-GET request to the remote agent for all OIDs specified in the _oids_ array. Returns a {SnmpGetRequest} object,
    # which implements EM::Deferrable. From there, implement a callback/errback to fetch the result. On success, the result will be
    # a hash, mapping requested OID values to results. Errors will be returned as a {SNMP::ResponseError}.
    # 
    # Optional arguments can be passed into _args_, including:
    # *  _return_raw_ - Return objects and errors as their raw SNMP types, such as SNMP::Integer instead of native Ruby integers, SNMP::OctetString instead of native Ruby strings, etc. (default: false)
    # *  _version_ - Override the version provided in the {SNMP4EM::Manager} constructor
 
    def get(oids, args = {})
      SnmpGetRequest.new(self, oids, args.merge(:version => @version))
    end

    # Sends an SNMP-GETNEXT request to the remote agent for all OIDs specified in the _oids_ array. Returns a {SnmpGetRequest} object,
    # which implements EM::Deferrable. From there, implement a callback/errback to fetch the result. On success, the result will be
    # a hash, mapping requested OID values to two-element arrays consisting of [_next_oid_ , _next_value_]. OIDs resulting in an
    # error will map to an instance of {SNMP::ResponseError} instead.
    # 
    # Optional arguments can be passed into _args_, including:
    # *  _return_raw_ - Return objects and errors as their raw SNMP types, such as SNMP::Integer instead of native Ruby integers, SNMP::OctetString instead of native Ruby strings, etc. (default: false)
    # *  _version_ - Override the version provided in the {SNMP4EM::Manager} constructor

    def getnext(oids, args = {})
      SnmpGetNextRequest.new(self, oids, args.merge(:version => @version))
    end

    # Sends an SNMP-SET request to the remote agent for all OIDs specified in the _oids_ hash. The hash must map OID values to requested
    # values. Values can either be specified as Ruby native strings/integers, or as SNMP-specific classes (SNMP::IpAddress, etc).
    # Returns a {SnmpSetRequest} object, which implements EM::Deferrable. From there, implement a callback/errback to fetch the result.
    # On success, the result will be a hash, mapping requested OID values to the returned value from the agent. Any values that were stored
    # successfully will map to _true_, otherwise, the value will map to an instance of {SNMP::ResponseError} instead.
    # 
    # Optional arguments can be passed into _args_, including:
    # *  _version_ - Override the version provided in the {SNMP4EM::Manager} constructor

    def set(oids, args = {})
      SnmpSetRequest.new(self, oids, args.merge(:version => @version))
    end

    # Sends a series of SNMP-GETNEXT requests to simulate an SNMP "walk" operation. Given an OID prefix, the library will keep requesting the
    # next OID until that returned OID does not begin with the requested prefix. This gives the ability to retrieve entire portions of the
    # SNMP tree in one "operation". Multiple OID prefixes can be passed into the _oids_ array, and will be fetched in parallel. The function returns
    # a {SnmpWalkRequest} object, which implements EM::Deferrable. From there, implement a callback/errback to fetch the result. On success, the
    # result will be a hash, mapping requested OID prefixes to the returned value. Successful walks will be mapped to a hash,
    # where each pair is represented as (oid => value). Unsuccessful walks will be mapped to an instance of {SNMP::ResponseError}.
    #
    # Optional arguments can be passed into _args_, including:
    # *  _return_raw_ - Return objects and errors as their raw SNMP types, such as SNMP::Integer instead of native Ruby integers, SNMP::OctetString instead of native Ruby strings, etc. (default: false)
    # *  _max_results_ - Maximum number of results to be returned for any single OID prefix (default: nil = unlimited)
    # *  _version_ - Override the version provided in the {SNMP4EM::Manager} constructor

    def walk(oids, args = {})
      SnmpWalkRequest.new(self, oids, args.merge(:version => @version))
    end
  end
end

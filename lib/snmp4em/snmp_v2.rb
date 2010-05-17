# The SNMP4EM library 

module SNMP4EM
  class SNMPv2 < SnmpConnection
    attr_reader :community_ro, :community_rw
    
    # Creates a new object to communicate with SNMPv1 agents. Optionally pass in the following parameters:
    # *  _host_ - IP/hostname of remote agent (default: 127.0.0.1)
    # *  _port_ - UDP port on remote agent (default: 161)
    # *  _community_ - Community string to use (default: public)
    # *  _community_ro_ - Read-only community string to use for get/getnext/walk operations (default: public)
    # *  _community_rw_ - Read-write community string to use for set operations (default: public)
    # *  _timeout_ - Number of seconds to wait before a request times out (default: 1)
    # *  _retries_ - Number of retries before failing (default: 3)
    
    def initialize(args = {})
      super(args)
      
      @community_ro = args[:community_ro] || args[:community] || "public"
      @community_rw = args[:community_rw] || args[:community] || "public"
    end
    
    # Sends an SNMP-GET request to the remote agent for all OIDs specified in the _oids_ array. Returns a SnmpGetRequest object,
    # which implements EM::Deferrable. From there, implement a callback/errback to fetch the result. On success, the result will be
    # a hash, mapping requested OID values to results.
    # 
    # Optional arguments can be passed into _args_, including:
    # *  _return_raw_ - Return objects and errors as their raw SNMP types, such as SNMP::Integer instead of native Ruby integers, SNMP::OctetString instead of native Ruby strings, etc. (default: false)
 
    def get(oids, args = {})
      request = SnmpGetRequest.new(self, oids, args.merge(:version => :SNMPv2c))
      SnmpConnection.pending_requests << request
      return request
    end

    # Sends an SNMP-GETNEXT request to the remote agent for all OIDs specified in the _oids_ array. Returns a SnmpGetRequest object,
    # which implements EM::Deferrable. From there, implement a callback/errback to fetch the result. On success, the result will be
    # a hash, mapping requested OID values to two-element arrays consisting of [_next_oid_ , _next_value_]. Any values that produced an
    # error will map to a symbol representing the error.
    # 
    # Optional arguments can be passed into _args_, including:
    # *  _return_raw_ - Return objects and errors as their raw SNMP types, such as SNMP::Integer instead of native Ruby integers, SNMP::OctetString instead of native Ruby strings, etc. (default: false)

    def getnext(oids, args = {})
      request = SnmpGetNextRequest.new(self, oids, args.merge(:version => :SNMPv2c))
      SnmpConnection.pending_requests << request
      return request
    end

    # Sends an SNMP-SET request to the remote agent for all OIDs specified in the _oids_ hash. The hash must map OID values to requested
    # values. Values can either be specified as Ruby native strings/integers, or as SNMP-specific classes (SNMP::IpAddress, etc).
    # Returns a SnmpSetRequest object, which implements EM::Deferrable. From there, implement a callback/errback to fetch the result.
    # On success, the result will be a hash, mapping requested OID values to the returned value from the agent. Any values that were stored
    # successfully will map to _true_, otherwise, the value will map to a symbol representing the error.
    # 
    # Optional arguments can be passed into _args_, including:
    # *  _return_raw_ - Return error objects as SNMP::ResponseError instead of a symbol

    def set(oids, args = {})
      request = SnmpSetRequest.new(self, oids, args.merge(:version => :SNMPv2c))
      SnmpConnection.pending_requests << request
      return request
    end

    # Sends a series of SNMP-GETNEXT requests to simulate an SNMP "walk" operation. Given an OID prefix, the library will keep requesting the
    # next OID until that returned OID does not begin with the requested prefix. This gives the ability to retrieve entire portions of the
    # SNMP tree in one "operation". Multiple OID prefixes can be passed into the _oids_ array, and will be fetched in parallel. The function returns
    # a SnmpWalkRequest object, which implements EM::Deferrable. From there, implement a callback/errback to fetch the result. On success, the
    # result will be a hash, mapping requested OID prefixes to the returned value. Successful walks will be mapped to an array of two-element arrays,
    # each of which consists of [_oid_ , _value_]. Unsuccessful walks will be mapped to a symbol representing the error.

    # Optional arguments can be passed into _args_, including:
    # *  _return_raw_ - Return objects and errors as their raw SNMP types, such as SNMP::Integer instead of native Ruby integers, SNMP::OctetString instead of native Ruby strings, etc. (default: false)
    # *  _max_results_ - Maximum number of results to be returned for any single OID prefix (default: nil = unlimited)

    def walk(oids, args = {})
      request = SnmpWalkRequest.new(self, oids, args.merge(:version => :SNMPv2c))
      SnmpConnection.pending_requests << request
      return request
    end
    
    # Sends an SNMPv2 GET-BULK request to fetch multiple OID-value pairings simultaneously. This produces similar results to an SNMP-WALK using a single
    # request/response transaction (SNMP-WALK is actually an inefficient series of GET-NEXTs). Multiple OIDs can be passed into the _oids_ array. Two
    # additional parameters control how this list is processed. Setting the parameter _nonrepeaters_ to value _N_ indicates that the first _N_ OIDs will
    # fetch a single value. This is identical to running a single GET-NEXT for the OID. Any remaining OIDs will fetch multiple values. The number of values
    # fetched is controlled by the parameter _maxrepetitions_. The function returns a SnmpGetBulkRequest object, which implements EM::Deferrable. From there,
    # implement a callback/errback to fetch the result. On success, the result will be a hash, mapping requested OID prefixes to the returned value.
    # Successful fetches will be mapped to an array of two-element arrays, each of which consists of [_oid_ , _value_]. Unsuccessful fetches will be mapped to a
    # symbol representing the error.
    
    # For more information, see http://tools.ietf.org/html/rfc1905#section-4.2.3
    
    # Optional arguments can be passed into _args_, including:
    # *  _return_raw_ - Return objects and errors as their raw SNMP types, such as SNMP::Integer instead of native Ruby integers, SNMP::OctetString instead of native Ruby strings, etc. (default: false)
    # *  _nonrepeaters_ - Number of OIDs passed to which exactly one result will be returned
    # *  _maxrepetitions_ - Number of OID-value pairs to be returned for each OID

    def getbulk(oids, args = {})
      request = SnmpGetBulkRequest.new(self, oids, args.merge(:version => :SNMPv2c))
      SnmpConnection.pending_requests << request
      return request
    end
  end
end
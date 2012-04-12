# The SNMP4EM library 

module SNMP4EM
  module SNMPv2cRequests
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
    # *  _nonrepeaters_ - Number of OIDs passed to which exactly one result will be returned (default is 0)
    # *  _maxrepetitions_ - Number of OID-value pairs to be returned for each OID (default is 10)

    def getbulk(oids, args = {})
      SnmpGetBulkRequest.new(self, oids, args.merge(:version => @version))
    end
  end
end

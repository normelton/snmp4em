# The SNMP4EM library 

module SNMP4EM
  # Provides access to send and receive SNMP messages via a UDP socket.
  #
  # _Note_ - The methods for actually sending requests are documented in {SNMP4EM::SNMPCommonRequests} and, for
  # those specific to SNMPv2, {SNMP4EM::SNMPv2cRequests}.
  class Manager
    include SNMP4EM::SNMPCommonRequests

    MAX_INDEX = 2**31  # @private Largest SNMP Signed INTEGER 

    #
    # @pending_requests maps a request's id to its SnmpRequest
    #
    @pending_requests = {}
    @socket = nil
    
    class << self
      attr_reader :pending_requests
      attr_reader :socket
      
      # Initializes the outgoing socket. Checks to see if it's in an error state, and if so closes and reopens the socket
      def init_socket
        if !@socket.nil? && @socket.error?
          @socket.close_connection
          @socket = nil
        end

        @next_index ||= rand(MAX_INDEX)
        @socket ||= EM::open_datagram_socket("0.0.0.0", 0, Handler)
      end

      # Assigns an SNMP ID to an outgoing request so that it can be matched with its incoming response
      def track_request(request)
        @pending_requests.delete(request.snmp_id)

        begin
          @next_index = (@next_index + 1) % MAX_INDEX
          request.snmp_id = @next_index
        end while @pending_requests[request.snmp_id]

        @pending_requests[request.snmp_id] = request
      end
    end
    
    attr_reader :host, :port, :timeout, :retries, :version, :community_ro, :community_rw
    
    # Creates a new object to communicate with SNMP agents. Optionally pass in the following parameters:
    # *  _host_ - IP/hostname of remote agent (default: 127.0.0.1)
    # *  _port_ - UDP port on remote agent (default: 161)
    # *  _community_ - Community string to use for all operations (default: public)
    # *  _community_ro_ - Read-only community string to use for read-only operations (default: public)
    # *  _community_rw_ - Read-write community string to use for read-write operations (default: public)
    # *  _timeout_ - Number of seconds to wait before a request times out (default: 1)
    # *  _retries_ - Number of retries before failing (default: 3)
    # *  _version_ - SNMP version, either :SNMPv1 or :SNMPv2c (default: :SNMPv2c)
    
    def initialize(args = {})
      @host    = args[:host]    || "127.0.0.1"
      @port    = args[:port]    || 161
      @timeout = args[:timeout] || 1
      @retries = args[:retries] || 3
      @version = args[:version] || :SNMPv2c
      @fiber   = args[:fiber]   || false

      self.extend SNMPv2cRequests if @version == :SNMPv2c

      @community_ro = args[:community_ro] || args[:community] || "public"
      @community_rw = args[:community_rw] || args[:community] || "public"
      
      self.class.init_socket
    end
    
    def send_msg(message) # @private
      self.class.socket.send_datagram message.encode, @host, @port
    end

    def wrap_in_fiber(request) # @private
      require "fiber"

      fiber = Fiber.current

      request.callback do |response|
        fiber.resume response
      end

      request.errback do |error|
        fiber.resume SNMP::RequestTimeout.new(error)
      end

      Fiber.yield
    end

  end
end

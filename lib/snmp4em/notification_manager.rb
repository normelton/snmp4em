module SNMP4EM
  # Provides access to receive SNMP traps (SNMPv1) and notifications (SNMPv2)
  class NotificationManager
    attr_reader :host, :port, :timeout, :retries, :version, :community_ro, :community_rw

    # Creates a new object to communicate with SNMP agents. Optionally pass in the following parameters:
    # *  _host_ - IP/hostname of local interface on which to listen (default: 127.0.0.1)
    # *  _port_ - UDP port on which to listen (default: 162)
    def initialize(args = {})
      @host    = args[:host]      || "127.0.0.1"
      @port    = args[:port]      || 162

      @socket = EM::open_datagram_socket(@host, @port, NotificationHandler)
    end

    # Register a callback that is upon reception of a trap/notification. Multiple callbacks can be
    # registered. Each will be passed the trap/notification object. It is important to determine whether
    # it is a SNMP::SNMPv1_Trap or SNMP::SNMPv2_Trap, as each behaves slightly differently.
    def on_trap &block
      @socket.callbacks << block
    end
  end
end
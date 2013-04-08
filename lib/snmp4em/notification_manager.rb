module SNMP4EM
  class NotificationManager
    attr_reader :host, :port, :timeout, :retries, :version, :community_ro, :community_rw

    def initialize(args = {})
      @host    = args[:host]      || "127.0.0.1"
      @port    = args[:port]      || 162

      @socket = EM::open_datagram_socket(@host, @port, NotificationHandler)
    end

    def on_trap &block
      @socket.callbacks << block
    end
  end
end
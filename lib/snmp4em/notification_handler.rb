module SNMP4EM
  class NotificationHandler < EventMachine::Connection #:nodoc:
    attr_accessor :callbacks

    def post_init
      @callbacks = []
    end

    def receive_data(data)
      source_port, source_ip = Socket.unpack_sockaddr_in(get_peername)

      begin
        message = SNMP::Message.decode(data)
      rescue Exception => err
        return
      end

      trap = message.pdu

      return unless trap.is_a?(SNMP::SNMPv1_Trap) || trap.is_a?(SNMP::SNMPv2_Trap)

      trap.source_ip = source_ip

      @callbacks.each { |callback| callback.yield(message.pdu) }
    end
  end
end

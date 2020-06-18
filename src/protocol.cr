require "./connection"
require "./connections/*"

module CelesteProtocol
  enum Protocol
    TCP
    UDP
  end

  module TCP
    TEAPOT = "HTTP/1.1 418 I'm a teapot\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"

    def self.get_connection_type(message)
      return CelesteNetConnection
    end

    def self.handle_client(client)
      spawn do
        # client.keepalive = true
        # client.tcp_keepalive_idle = 20
        # client.tcp_keepalive_interval = 10
        # client.tcp_keepalive_count = 3
        # client.tcp_nodelay = true
        client.puts TEAPOT
        data = Bytes.new(500)
        address = client.remote_address
        begin
          until client.closed?
            client.read data
            self.handle(data, client)
            Fiber.yield
          end
        rescue Socket::Error
          if connection = Server.instance.tcp_connections[address]?
            connection.close
          end
        end
      end
    end

    def self.handle(message, from)
      connection : Connection
      if existing_connection = Server.instance.tcp_connections[from.remote_address]?
        connection = existing_connection
      else
        connection = get_connection_type(message).new(from)
        Server.instance.tcp_connections[from.remote_address] = connection
      end
      connection.handle message
    end
  end

  module UDP
    def self.handle(message, from)
      if connection = Server.instance.udp_connections[from]?
        connection.handle message.to_slice
      end
    end
  end
end

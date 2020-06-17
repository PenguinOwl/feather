require "socket"
require "./patch"
require "./feather_data"

abstract class Connection
  Log = ::Log.for("connection")

  property remote : Socket::IPAddress
  property client : TCPSocket
  property id : UInt32
  property data
  property tcp_mutex
  property udp_mutex
  getter closed = false

  @@connection_counter : UInt32 = 1

  def initialize(client)
    @remote = client.remote_address
    @client = client
    @tcp_mutex = Mutex.new
    @udp_mutex = Mutex.new
    @id = @@connection_counter
    @@connection_counter += 1
    @data = FeatherData::PlayerData.new(id: id)
  end

  def closed?
    return closed
  end

  def close
    return if closed?
    server = Server.instance
    spawn do
      server.handle_disconnection id
      server.tcp_connections.reject! { |k, v| v == self }
      server.udp_connections.reject! { |k, v| v == self }
      client.close
      @closed = true
      Log.info { "#{data.name}##{id} disconneted from the server" }
    end
  end

  def send_tcp(packet)
    spawn do
      tcp_mutex.synchronize do
        begin
          client.send(packet)
        rescue IO::Error
          close
        end
      end
    end
  end

  def send_udp(packet)
    spawn do
      udp_mutex.synchronize do
        begin
          Server.instance.udp_server.send(packet, to: Server.instance.udp_connections.key_for(self))
        rescue IO::Error
          close
        end
      end
    end
  end

  abstract def handle(data)
  abstract def send_chat(data)
  abstract def send_player_state(data)
  abstract def send_player_info(data)
  abstract def send_player_frame(data)
  abstract def send_emote(data)
end

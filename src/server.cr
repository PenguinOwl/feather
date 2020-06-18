require "socket"
require "./connection"
require "./protocol"
require "./server_events"
require "./server_logic"

class Server
  Log = ::Log.for("server")

  @@instance : Server | Nil = nil

  property tcp_port : Int32
  property udp_port : Int32

  property tcp_server : TCPServer
  property udp_server : UDPSocket

  property running = false
  property tcp_connections = {} of Socket::IPAddress => Connection
  property udp_connections = {} of Socket::IPAddress => Connection

  def self.instance
    return @@instance.not_nil!
  end

  def initialize(tcp_port, udp_port)
    Log.info { "Initalizing server" }
    Log.info { "Initializing on TCP port #{tcp_port} and UDP port #{udp_port}" }
    @tcp_port = tcp_port
    @udp_port = udp_port
    Log.info { "Initalizing TCP and UDP servers" }
    @tcp_server = TCPServer.new("0.0.0.0", tcp_port)
    @udp_server = UDPSocket.new
    @udp_server.bind("0.0.0.0", udp_port)
    @@instance = self
  end

  def running?
    return running
  end

  def start
    stop if running

    Log.info { "Starting server" }
    Log.info { "Starting TCP and UDP servers" }
    @running = true

    spawn do
      Log.info { "TCP server is ready" }
      while running
        Fiber.yield
        if client = tcp_server.accept?
          CelesteProtocol::TCP.handle_client client
        end
      end
      Log.info { "TCP server is stopped" }
    end

    spawn do
      Log.info { "UDP server is ready" }
      while running
        Fiber.yield
        CelesteProtocol::UDP.handle *udp_server.receive
      end
      Log.info { "UDP server is stopped" }
    end
  end

  def stop
    Log.info { "Stopping server" }
    Log.info { "Stopping TCP and UDP servers" }
    tcp_server.close unless tcp_server.closed?
    udp_server.close unless tcp_server.closed?
    @running = false
    Fiber.yield
  end
end

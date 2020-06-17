require "./server"
require "log"

module Feather
  VERSION = "0.1.0"

  Log.info { "Starting Feather version #{VERSION}" }

  start_time = Time.utc

  server = Server.new(3802, 3802)
  server.start

  Log.info { "Server started in #{(Time.utc - start_time).to_f.round 4}s" }

  while server.running?
    Fiber.yield
  end
end

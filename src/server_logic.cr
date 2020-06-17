class Server
  def connection(id)
    return tcp_connections.values.find { |e| e.id == id }.not_nil!
  end

  def connections(id)
    return tcp_connections.values
  end

  def other_connections(id)
    return tcp_connections.values.where { |e| e.id = !id }
  end

  def each_connection
    tcp_connections.values.each do |e|
      yield e
    end
  end

  def each_other_connection(id)
    tcp_connections.values.each do |e|
      next if e.id == id
      yield e
    end
  end
end

class Server
  def connection(id)
    return tcp_connections.values.find { |e| e.id == id }.not_nil!
  end

  def connections
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

  def each_connection(id)
    whitelist = channel_list.filter(id).values.map(&.players).flatten
    tcp_connections.values.each do |e|
      next unless whitelist.includes? e.id
      yield e
    end
  end

  def each_other_connection(id)
    whitelist = channel_list.filter(id).values.map(&.players).flatten
    tcp_connections.values.each do |e|
      next unless whitelist.includes? e.id
      next if e.id == id
      yield e
    end
  end

  def each_connection_in_channel(id)
    whitelist = channel_list[connection(id).channel].players
    tcp_connections.values.each do |e|
      next unless whitelist.includes? e.id
      yield e
    end
  end

  def each_other_connection_in_channel(id)
    whitelist = channel_list[connection(id).channel].players
    tcp_connections.values.each do |e|
      next if e.id == id
      next unless whitelist.includes? e.id
      yield e
    end
  end
end

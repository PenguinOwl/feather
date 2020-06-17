require "./feather_data"

class Server
  def handle_new_connection(from)
    connection = connection(from)
    player_data = connection.data
    chat = FeatherData::Chat.new(
      color: FeatherData::Color.new(
        red: 0x9e,
        green: 0x24,
        blue: 0xf5,
      ),
      text: "#{player_data.name}##{player_data.id} joined the server!"
    )
    each_connection do |conn|
      conn.send_chat chat
    end
    each_other_connection(from) do |conn|
      connection.send_player_info conn.data
      conn.send_player_info connection.data
    end
  end

  def handle_disconnection(from)
    player_data = connection(from).data
    chat = FeatherData::Chat.new(
      color: FeatherData::Color.new(
        red: 0x9e,
        green: 0x24,
        blue: 0xf5,
      ),
      text: "#{player_data.name}##{player_data.id} disconnected from the server!"
    )
    player_data = player_data.dup
    player_data.name = ""
    each_other_connection(from) do |conn|
      conn.send_chat chat
      conn.send_player_info player_data
    end
  end

  def handle_chat(from, chat)
    chat.player_data.id = from
    each_connection do |conn|
      conn.send_chat chat
    end
  end

  def handle_player_info(from, player_info)
    return unless player_info.id == from
    each_other_connection(from) do |conn|
      conn.send_player_info player_info
    end
  end

  def handle_player_state(from, player_state)
    return unless player_state.id == from
    each_other_connection(from) do |conn|
      conn.send_player_state player_state
    end
  end

  def handle_player_frame(from, player_frame)
    player_frame.player_id = from
    each_other_connection(from) do |conn|
      conn.send_player_frame player_frame
    end
  end

  def handle_emote(from, emote)
    emote.player_id = from
    each_other_connection(from) do |conn|
      conn.send_emote emote
    end
  end
end

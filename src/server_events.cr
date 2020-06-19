require "./feather_data"

class Server
  COMMAND_PREFIX = "/"

  def handle_new_connection(from)
    connection = connection(from)
    player_data = connection.data
    chat = FeatherData::Chat.new(
      color: FeatherData::Color::PURPLE,
      text: "#{player_data.name}##{player_data.id} joined the server!"
    )
    each_other_connection(from) do |conn|
      connection.send_player_info conn.data
      connection.send_player_state conn.state
      conn.send_player_info connection.data
    end
    handle_channel_update
    each_connection(from) do |conn|
      conn.send_chat chat
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
    spawn do
      sleep 1
      handle_channel_update
    end
  end

  def handle_chat(from, chat)
    chat.player_data.id = from
    each_connection_in_channel(from) do |conn|
      conn.send_chat chat
    end
  end

  def handle_player_info(from, player_info)
    return unless player_info.id == from
    each_other_connection(from) do |conn|
      conn.send_player_info player_info
      puts conn
    end
  end

  def handle_player_state(from, player_state)
    return unless player_state.id == from
    connection(from).state = player_state
    each_other_connection(from) do |conn|
      conn.send_player_state player_state
    end
  end

  def handle_player_frame(from, player_frame)
    player_frame.player_id = from
    each_other_connection_in_channel(from) do |conn|
      conn.send_player_frame player_frame
    end
  end

  def handle_emote(from, emote)
    emote.player_id = from
    each_other_connection_in_channel(from) do |conn|
      conn.send_emote emote
    end
  end

  def handle_channel_update
    channel_list.update
    each_connection do |conn|
      conn.send_channel_list channel_list.filter(conn.id)
    end
  end

  def handle_channel_change(from, channel_move)
    connection = connection(from)
    each_connection_in_channel(from) do |conn|
      conn.send_channel_move channel_move
    end
    connection.channel = channel_move.channel_id
    handle_channel_update
    handle_player_state(from, connection.state)
    each_other_connection_in_channel(from) do |conn|
      connection.send_player_state(conn.state)
    end
  end

  def handle_command(from, command)
    args = command.args
    connection = connection(from)
    case command.command
    when "channel"
      if id = args[0]?
        channel_data = FeatherData::ChannelMove.new(player_id: from)
        if channel_id = id.to_u32?
          channel_data.channel_id = channel_id
        elsif channel = channel_list.find{ |k, v| v.name.downcase == id.downcase }
          channel_data.channel_id = channel[0]
        else
          connection.send_chat(FeatherData::Chat.new(
            color: FeatherData::Color::GREEN,
            text: "Failed to connect to channel #{id}. To create a new channel, run #{COMMAND_PREFIX}channel <number>"
          ))
          return
        end
        handle_channel_change(from, channel_data)
        connection.send_chat(FeatherData::Chat.new(
          color: FeatherData::Color::GREEN,
          text: "Connected to channel #{id}, #{channel_list[connection.channel].name}"
        ))
      else
        connection.send_chat(FeatherData::Chat.new(
          color: FeatherData::Color::GREEN,
          text: "You are on channel #{connection.channel}, #{channel_list[connection.channel].name}"
        ))
      end
    else
      connection.send_chat(FeatherData::Chat.new(
        color: FeatherData::Color::RED,
        text: "Invalid command. Try doing #{COMMAND_PREFIX}help"
      ))
    end
  end

end

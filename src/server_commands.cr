class Server

  macro success(text))
    connection.send_chat(FeatherData::Chat.new(
      color: FeatherData::Color::GREEN,
      text: {{text}}
    ))
  end

  macro error(text))
    connection.send_chat(FeatherData::Chat.new(
      color: FeatherData::Color::RED,
      text: {{text}}
    ))
  end

  def handle_command(from, command)
    args = command.args
    connection = connection(from)
    case command.command
    when "help", "?"
      connection.send_chat FeatherData::Chat.new(
        color: FeatherData::Color::TEAL,
        text: <<-HERE
        Feather Commands:
        #{COMMAND_PREFIX}help - shows this menu
        #{COMMAND_PREFIX}channel <id/name> - switches channels
        #{COMMAND_PREFIX}channelname <name> - sets the channel name
        #{COMMAND_PREFIX}whisper <id> <message> - whispers a message to another player
        HERE
      )
    when "channel", "c"
      if id = args[0]?
        channel_data = FeatherData::ChannelMove.new(player_id: from)
        if channel_id = id.to_u32?
          channel_data.channel_id = channel_id
        elsif channel = channel_list.find{ |k, v| v.name.downcase == id.downcase }
          channel_data.channel_id = channel[0]
        else
          error "Failed to connect to channel #{id}. To create a new channel, run #{COMMAND_PREFIX}channel <number>"
          return
        end
        handle_channel_change(from, channel_data)
        success "Connected to channel #{connection.channel}, #{channel_list[connection.channel].name}"
      else
        success "You are on channel #{connection.channel}, #{channel_list[connection.channel].name}"
      end
    when "channelname", "cn"
      channel = channel_list[connection.channel]
      if channel.owner == connection.id
        unless args.empty?
          channel.name = args.join(" ")
          success "Changed channel name to #{channel_list[connection.channel].name}."
          handle_channel_change channel.owner, FeatherData::ChannelMove.new(player_id: channel.owner, channel_id: connection.channel)
        else
          error "Channel name cannot be blank!"
        end
      else
        error "You are not the owner of this channel. Ask #{connection(channel.owner).data.name} to change the name."
      end
    when "whisper", "w"
      if player = args[0]?
        if message_parts = args[1..-1]?
          player_id = 0
          if player_id_arg = player.to_u32?
            player_id = player_id_arg
          elsif player_conn = connections.find{ |e| e.data.name.downcase == player.downcase }
            player_id = player_conn.data.id
          else
            error "Could not find player #{player}."
            return
          end
          message = message_parts.join(' ')
          other_connection = connection(player_id)
          connection.send_chat(FeatherData::Chat.new(
            color: FeatherData::Color::ORANGE,
            text: "->#{other_connection.data.name}##{player_id} #{message}"
          ))
          other_connection.send_chat(FeatherData::Chat.new(
            color: FeatherData::Color::ORANGE,
            text: "#{connection.data.name}##{from}-> #{message}"
          ))
        else
          error "Message cannot be empty."
        end
      else
        error "Missing player name or id."
      end
    else
      error "Invalid command. Try doing #{COMMAND_PREFIX}help"
    end
  end

end

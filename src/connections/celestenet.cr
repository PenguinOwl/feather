require "../connection"
require "bindata"

class CelesteNetConnection < Connection
  Log = ::Log.for("celestenet")

  def initialize(client)
    super(client)
    keepalive = Packet(Keepalive).new
    spawn do
      until closed?
        sleep 1
        send_udp keepalive
      end
    end
  end

  def handle(data)
    packet = data.read_bytes(Packet(Data))
    case packet.data_type
    when "hsTUC"
      packet = data.read_bytes(Packet(TCPHandshake))
      Log.info { "Received handshake for #{packet.content.name} from #{remote}" }
      @data.name = packet.content.name
      Server.instance.udp_connections[Socket::IPAddress.new(client.remote_address.address, packet.content.udp_port)] = self

      return_packet = Packet(ServerHandshake).new
      handshake = return_packet.content
      handshake.version = 1
      handshake.player_info.id = id
      handshake.player_info.name = packet.content.name
      handshake.player_info.full_name = packet.content.name

      send_tcp return_packet
      Log.info { "Sent handshake for id #{handshake.player_info.id} to #{remote}" }
      Server.instance.handle_new_connection id
    when "playerFrame"
      packet = data.read_bytes(Packet(PlayerFrame))
      player_frame = packet.content
      player_frame_data = FeatherData::PlayerFrame.new(
        update_id: player_frame.update_id,
        player_id: player_frame.player_id,
        position: {player_frame.position.x, player_frame.position.y},
        speed: {player_frame.speed.x, player_frame.speed.y},
        scale: {player_frame.scale.x, player_frame.scale.y},
        color: player_frame.color.to_color,
        facing_left: player_frame.facing_dir,
        sprite_mode: player_frame.sprite_mode,
        sprite_rate: player_frame.sprite_rate,
        facing_dir: player_frame.is_facing ? {player_frame.facing.direction.x, player_frame.facing.direction.y} : nil,
        current_anim_id: player_frame.current_anim_id,
        current_anim_frame: player_frame.current_anim_frame,
        hair_color: player_frame.hair_color.to_color,
        hair_motion: player_frame.hair_motion,
        hair_colors: player_frame.hair_colors.map &.to_color,
        hair_textures: player_frame.hair_textures,
        dash_color: player_frame.has_dash_color ? player_frame.dash_color.value.to_color : nil,
        dash_direction: {player_frame.dash_direction.x, player_frame.dash_direction.y},
        dash_was_b: player_frame.dash_was_b,
        dead: player_frame.dead
      )
      Server.instance.handle_player_frame(id, player_frame_data)
    when "chat"
      packet = data.read_bytes(Packet(Chat))
      chat_data = FeatherData::Chat.new
      chat = packet.content
      chat_data.player_data.id = chat.player_id
      chat_data.color.red = chat.r
      chat_data.color.green = chat.g
      chat_data.color.blue = chat.b
      chat_data.text = chat.text
      chat_data.tag = chat.tag
      chat_data.time = chat.time.value
      Server.instance.handle_chat(id, chat_data)
    when "playerInfo"
      packet = data.read_bytes(Packet(PlayerInfo))
      @data.name = packet.content.name
      Server.instance.handle_player_info(id, @data)
    when "playerState"
      packet = data.read_bytes(Packet(PlayerState))
      player_state = packet.content
      player_state_data = FeatherData::PlayerState.new
      player_state_data.id = player_state.id
      player_state_data.channel = player_state.channel
      player_state_data.sid = player_state.sid
      player_state_data.mode = player_state.mode
      player_state_data.idle = player_state.idle
      Server.instance.handle_player_state(id, player_state_data)
    when "emote"
      packet = data.read_bytes(Packet(Emote))
      emote = packet.content
      emote_data = FeatherData::Emote.new
      emote_data.player_id = emote.player_id
      emote_data.text = emote.text
      Server.instance.handle_emote(id, emote_data)
    end
  end

  def send_chat(chat_data)
    packet = Packet(Chat).new
    chat = packet.content

    chat.player_id = chat_data.player_data.id
    chat.r = chat_data.color.red.to_u8
    chat.g = chat_data.color.green.to_u8
    chat.b = chat_data.color.blue.to_u8
    chat.text = chat_data.text
    chat.tag = chat_data.tag
    chat.time.value = chat_data.time
    chat.id = chat_data.id
    send_tcp packet
  end

  def send_player_state(player_state_data)
    packet = Packet(PlayerState).new
    player_state = packet.content
    player_state.id = player_state_data.id
    player_state.channel = player_state_data.channel
    player_state.sid = player_state_data.sid
    player_state.mode = player_state_data.mode
    player_state.idle = player_state_data.idle
    send_tcp packet
  end

  def send_player_info(player_info_data)
    packet = Packet(PlayerInfo).new
    player_info = packet.content
    player_info.id = player_info_data.id
    player_info.name = player_info_data.name
    player_info.full_name = player_info_data.name
    send_tcp packet
  end

  def send_player_frame(player_frame_data)
    packet = Packet(PlayerFrame).new
    player_frame = packet.content
    player_frame.update_id = player_frame_data.update_id
    player_frame.player_id = player_frame_data.player_id
    player_frame.position.x = player_frame_data.position[0]
    player_frame.position.y = player_frame_data.position[1]
    player_frame.speed.x = player_frame_data.speed[0]
    player_frame.speed.y = player_frame_data.speed[1]
    player_frame.scale.x = player_frame_data.scale[0]
    player_frame.scale.y = player_frame_data.scale[1]
    player_frame.color = Color.from_color(player_frame_data.color)
    player_frame.facing_dir = player_frame_data.facing_left
    player_frame.sprite_mode = player_frame_data.sprite_mode
    player_frame.sprite_rate = player_frame_data.sprite_rate
    if facing_dir = player_frame_data.facing_dir
      player_frame.is_facing = true
      player_frame.facing.direction.x = facing_dir[0]
      player_frame.facing.direction.y = facing_dir[1]
    else
      player_frame.is_facing = false
    end
    player_frame.current_anim_id = player_frame_data.current_anim_id
    player_frame.current_anim_frame = player_frame_data.current_anim_frame
    player_frame.hair_color = Color.from_color player_frame_data.hair_color
    player_frame.hair_motion = player_frame_data.hair_motion
    player_frame.hair_count = player_frame_data.hair_colors.size.to_u8
    player_frame.hair_colors = player_frame_data.hair_colors.map { |e| Color.from_color(e) }
    player_frame.hair_textures = player_frame_data.hair_textures
    if dash_color = player_frame_data.dash_color
      player_frame.has_dash_color = true
      player_frame.dash_color.value = Color.from_color(dash_color)
    else
      player_frame.has_dash_color = false
    end
    player_frame.dash_direction.x = player_frame_data.dash_direction[0]
    player_frame.dash_direction.y = player_frame_data.dash_direction[1]
    player_frame.dash_was_b = player_frame_data.dash_was_b
    player_frame.dead = player_frame_data.dead
    send_udp packet
  end

  def send_emote(emote_data)
    packet = Packet(Emote).new
    emote = packet.content
    emote.player_id = emote_data.player_id
    emote.text = emote_data.text
    send_tcp packet
  end

  class Packet(T) < BinData
    @[Flags]
    enum DataFlags
      None         =          0
      Update       =        256
      ForceForward = 0b01000000
      Reserved     = 0b00000001
    end
    endian little
    string :data_type, default: T.id
    bit_field do
      enum_bits 16, data_flags : DataFlags = DataFlags::None
    end
    uint16 :length, value: ->{ content.to_slice.size }
    custom content : T = T.new
  end

  class Data < BinData
    @@data_id = :none
    endian little

    def self.id
      return @@data_id.to_s
    end
  end

  class TCPHandshake < Data
    @@data_id = :hsTUC
    uint16 :version
    string :name
    int32 :udp_port
  end

  class ServerHandshake < Data
    @@data_id = :hsS
    uint16 :version
    custom player_info : PlayerInfo = PlayerInfo.new
  end

  class PlayerInfo < Data
    @@data_id = :playerInfo
    uint32 :id
    string :name
    string :full_name
  end

  class Color < Data
    uint8 :r
    uint8 :g
    uint8 :b
    uint8 :a

    def self.from_color(color_data)
      color = self.new
      color.r = color_data.red
      color.g = color_data.green
      color.b = color_data.blue
      color.a = color_data.alpha
      return color
    end

    def to_color
      color = FeatherData::Color.new
      color.red = r
      color.green = g
      color.blue = b
      color.alpha = a
      return color
    end
  end

  class TickTime < Data
    EPOCH      = Time.utc(year: 1, month: 1, day: 1)
    UTC_KIND   = 0x4000000000000000.to_u64
    TICKS_MASK = 0x3FFFFFFFFFFFFFFF
    uint64 :raw, default: convert(Time.utc)

    def value
      ticks = raw & TICKS_MASK
      return EPOCH + Time::Span.new(nanoseconds: ticks % 10_000_000, seconds: ticks // 10_000_000)
    end

    def value=(date)
      span = date - EPOCH
      ticks = span.to_i.to_u64 * 10_000_000 + span.nanoseconds // 100
      @raw = ticks | UTC_KIND
    end

    def self.convert(date)
      span = date - EPOCH
      ticks = span.to_i.to_u64 * 10_000_000 + span.nanoseconds // 100
      return ticks | UTC_KIND
    end
  end

  class Chat < Data
    @@data_id = :chat
    uint32 :player_id
    uint32 :id
    string :tag
    string :text
    uint8 :r
    uint8 :g
    uint8 :b
    custom time : TickTime = TickTime.new
  end

  class Emote < Data
    @@data_id = :emote
    uint32 :player_id
    string :text
  end

  class Keepalive < Data
    @@data_id = :keepalive
  end

  class Vector2 < Data
    float32 :x, default: 0
    float32 :y, default: 0
  end

  class PlayerFrame < Data
    @@data_id = :playerFrame
    uint32 :update_id
    uint32 :player_id
    custom position : Vector2 = Vector2.new
    custom speed : Vector2 = Vector2.new
    custom scale : Vector2 = Vector2.new
    custom color : Color = Color.new
    byte_bool :facing_dir
    uint8 :sprite_mode
    float32 :sprite_rate
    byte_bool :is_facing
    group :facing, onlyif: ->{ is_facing } do
      custom direction : Vector2 = Vector2.new
    end
    string :current_anim_id
    int32 :current_anim_frame
    custom hair_color : Color = Color.new
    byte_bool :hair_motion
    uint8 :hair_count
    variable_array hair_colors : Color, read_next: ->{ hair_colors.size < hair_count }
    variable_array hair_textures : String, read_next: ->{ hair_textures.size < hair_count }
    byte_bool :has_dash_color
    group :dash_color, onlyif: ->{ has_dash_color } do
      custom value : Color = Color.new
    end
    custom dash_direction : Vector2 = Vector2.new
    byte_bool :dash_was_b
    byte_bool :dead

    def hair_textures
      array = previous_def
      return array.tap &.each_with_index { |e, i| array[i] = e == "-" ? array[i - 1] : e }
    end

    def hair_textures=(val)
      previous_def val.map_with_index { |e, i| e == array[i - 1]? ? "-" : e }
    end
  end

  class PlayerState < Data
    @@data_id = :playerState
    uint32 :id
    uint32 :channel
    string :sid
    uint8 :mode
    string :level
    byte_bool :idle
  end

  class Unparsed < Data
    @@data_id = :unparsed
    string :inner_id
    bit_field do
      enum_bits 16, inner_flags : Packet::DataFlags = Packet::DataFlags::None
    end
    uint16 :inner_length
    bytes :bytes, length: ->{ inner_length }
  end
end

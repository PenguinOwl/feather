require "../connection"
require "bindata"

class GhostNetConnection < Connection
  Log = ::Log.for("ghostnet")

  def handle(data)
    packet = data.read_bytes(Packet(Data))
    case packet.data_type
    end
  end

  def send_chat(chat_data)
    packet = Packet(Chat).new
    chat = packet.content
    send_tcp packet
  end

  def send_player_state(player_state_data)
    packet = Packet(PlayerState).new
    player_state = packet.content
    send_tcp packet
  end

  def send_player_info(player_info_data)
    packet = Packet(PlayerInfo).new
    player_info = packet.content
    send_tcp packet
  end

  def send_player_frame(player_frame_data)
    packet = Packet(PlayerFrame).new
    player_frame = packet.content
    send_udp packet
  end

  def send_emote(emote_data)
    packet = Packet(Emote).new
    send_tcp packet
  end

  def send_channel_list(channel_list_data)
  end

  def send_channel_move(channel_move_data)
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

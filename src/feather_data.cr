module FeatherData
  class PlayerData
    property id
    property name

    def initialize(id = UInt32::MAX, name = "")
      @id = id
      @name = name
    end
  end

  class PlayerState
    property id
    property sid
    property mode
    property level
    property idle

    def initialize(id = UInt32::MAX, sid = "", mode = 0_u8, level = "", idle = false)
      @id = id
      @sid = sid
      @mode = mode
      @level = level
      @idle = idle
    end
  end

  class Color
    macro color(color, string)
      {{color.id.upcase}} = Color.new(
        red: 0x{{string.id[0..1]}},
        green: 0x{{string.id[2..3]}},
        blue: 0x{{string.id[4..5]}}
      )
    end

    color :gray, "696969"
    color :green, "bada55"
    color :cyan, "7fe5f0"
    color :red, "ff0000"
    color :pink, "ff80ed"
    color :blue, "407294"
    color :white, "ffffff"
    color :yellow, "ffd700"
    color :teal, "008080"
    color :orange, "ffa500"
    color :purple, "8a2be2"

    property red : UInt8
    property green : UInt8
    property blue : UInt8
    property alpha : UInt8

    def initialize(red = 0, green = 0, blue = 0, alpha = 255)
      @red = red.to_u8
      @green = green.to_u8
      @blue = blue.to_u8
      @alpha = alpha.to_u8
    end
  end

  class Emote
    property player_id
    property text

    def initialize(player_id = 0_u32, text = "")
      @player_id = player_id
      @text = text
    end
  end

  class Chat
    property player_data
    property tag
    property text
    property color
    property time
    property id : UInt32
    @@chat_id = 1_u32

    def initialize(player_data = PlayerData.new, tag = "", text = "", color = Color.new, time = Time.utc)
      @id = @@chat_id
      @@chat_id += 1
      @player_data = player_data
      @tag = tag
      @text = text
      @color = color
      @time = time
    end
  end

  alias Vector2 = Tuple(Float32, Float32)

  class PlayerFrame
    property update_id
    property player_id
    property position
    property speed
    property scale
    property color
    property facing_left
    property sprite_mode
    property sprite_rate : Float32
    property facing_dir : Vector2?
    property current_anim_id
    property current_anim_frame
    property hair_color
    property hair_motion
    property hair_colors
    property hair_textures
    property dash_color : Color?
    property dash_direction
    property dash_was_b
    property dead

    def initialize(
      update_id = 0_u32,
      player_id = 0_u32,
      position = Vector2.new,
      speed = Vector2.new,
      scale = Vector2.new,
      color = Color.new,
      facing_left = false,
      sprite_mode = 0_u8,
      sprite_rate = 1.0,
      facing_dir = nil,
      current_anim_id = "",
      current_anim_frame = 0,
      hair_color = Color.new,
      hair_motion = true,
      hair_colors = [] of Color,
      hair_textures = [] of String,
      dash_color = nil,
      dash_direction = Vector2.new,
      dash_was_b = false,
      dead = false
    )
      @update_id = update_id
      @player_id = player_id
      @position = position
      @speed = speed
      @scale = scale
      @color = color
      @facing_left = facing_left
      @sprite_mode = sprite_mode
      @sprite_rate = sprite_rate
      @facing_dir = facing_dir
      @current_anim_id = current_anim_id
      @current_anim_frame = current_anim_frame
      @hair_color = hair_color
      @hair_motion = hair_motion
      @hair_colors = hair_colors
      @hair_textures = hair_textures
      @dash_color = dash_color
      @dash_direction = dash_direction
      @dash_was_b = dash_was_b
      @dead = dead
    end
  end

  class Channel
    property name : String
    property owner : UInt32
    property players

    def initialize(name, owner)
      @name = name
      @owner = owner
      @players = [] of UInt32
    end
  end

  class ChannelList < Hash(UInt32, Channel)
    ADJ = %w{alpine buttery coarse dreamy early fun green happy ionic jolly
kind lowly merry neat odd proud quirky robust strict tidy unique vivid witty young zesty}
    NOUN = %w{ant bear cat dog emu ferret gnu hawk ibex jackal kiwi lion moose newt owl penguin quail rat snake tuna vole walrus yak zebra}
    def update
      self.values.each &.players.clear
      self[0] = Channel.new("master", 0_u32) unless self[0]?
      Server.instance.each_connection do |conn|
        channel : Channel
        if null_checked_channel = self[conn.channel]?
          channel = null_checked_channel
        else
          channel = Channel.new(ADJ.sample + "-" + NOUN.sample, conn.id)
          self[conn.channel] = channel
        end
        channel.players << conn.id
      end
      reject! { |k, v| v.players.empty? }
      each do |k, v|
        unless v.players.includes? v.owner || v.owner == 0
          v.owner = v.players.first
        end
      end
      self[0] = Channel.new("master", 0_u32) unless self[0]?
    end
    def filter(id)
      return self.reject{ |k, v| v.name[0] == '!' && !v.players.includes? id }
    end
  end

  class Command
    property command
    property args
    property sender
    property time

    def initialize(command = "", args = [] of String, sender = 0_u32, time = Time.utc)
      @command = command
      @args = args
      @sender = sender
      @time = time
    end
  end

  class ChannelMove
    property player_id
    property channel_id

    def initialize(player_id = 0_u32, channel_id = 0_u32)
      @player_id = player_id
      @channel_id = channel_id
    end
  end

end

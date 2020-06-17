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
    property channel
    property sid
    property mode
    property level
    property idle

    def initialize(id = UInt32::MAX, channel = 0_u32, sid = "", mode = 0_u8, level = "", idle = false)
      @id = id
      @channel = channel
      @sid = sid
      @mode = mode
      @level = level
      @idle = idle
    end
  end

  class Color
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
end

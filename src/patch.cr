struct Slice(T)
  def read_bytes(type)
    io = IO::Memory.new self
    val = io.read_bytes type
    io.close
    return val
  end
end

class String
  def self.from_io(io, format)
    return (io.gets('\0') || "")[0..-2]
  end
  def to_io(io, format)
    val = io.write((self + '\0').to_slice)
    return val
  end
end

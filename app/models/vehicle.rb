class Vehicle
  attr_accessor :name, :width, :length, :height

  def initialize(hash)
    @vehicle_hash = hash
    @name = hash[:name]
    @width = hash[:width]
    @length = hash[:length]
    @height = hash[:height]
  end

  def to_s
    @vehicle_hash.to_s
  end

  def inspect
    @vehicle_hash.to_s
  end

  def method_missing(name, *args)
    @vehicle_hash.send(name, *args)
  end
end
class Vehicle
  attr_accessor :name, :width, :length, :height, :exception_areas

  def initialize(hash)
    @vehicle_hash = hash
    @name = hash[:name]
    @width = hash[:width]
    @length = hash[:length]
    @height = hash[:height]
    @exception_areas = Array.new
  end

  def to_s
    inspect
  end

  def inspect
    @vehicle_hash.to_s
  end

  def method_missing(name, *args)
    @vehicle_hash.send(name, *args)
  end
end
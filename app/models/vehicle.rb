class Vehicle
  attr_accessor :name, :width, :length, :height, :stop, :un, :exception_areas, :right_corner

  def initialize(hash)
    @vehicle_hash = hash
    @name = hash[:name]
    @width = hash[:width]
    @length = hash[:length]
    @height = hash[:height]
    @stop = hash[:stop]
    @un = hash[:UN]
    @right_corner = false
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
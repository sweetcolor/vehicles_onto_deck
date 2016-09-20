class Cell
  attr_accessor :height, :name, :filled

  def initialize(hash)
    @cell_hash = hash
    @height = hash[:height]
    @name = hash[:name]
    @filled = hash[:filled]
  end

  def to_s
    inspect
  end

  def inspect
    { height: @height, name: @name, filled: @filled }.to_s
  end

  def method_missing(name, *args)
    @cell_hash.send(name, *args)
  end
end
class CellCursor
  attr_accessor :width, :length

  def initialize(width, length)
    @width = width
    @length = length
  end

  def inspect
    '(%s, %s)' % [@width, @length]
  end

  def to_s
    inspect
  end

  def +(other)
    CellCursor.new(@width+other.width, @length+other.length)
  end
end

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

  def w_plus(val)
    CellCursor.new(@width+val, @length)
  end

  def l_plus(val)
    CellCursor.new(@width, @length+val)
  end

  def w_minus(val)
    CellCursor.new(@width-val, @length)
  end

  def l_minus(val)
    CellCursor.new(@width, @length-val)
  end
end
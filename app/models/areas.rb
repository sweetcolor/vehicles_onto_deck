class Areas
  attr_reader :areas_array

  def initialize(areas_array, placement)
    @areas_array = areas_array
    @placement = placement
    sort
    # @sorted_by_width = sort_by_width
    # @sorted_by_length = sort_by_length
  end

  def reset(areas_array)
    unless areas_array.empty?
      @areas_array.clear
      @areas_array = areas_array + @sorted_array
    end
    sort
  end

  def get_next
    ul_placement? ? upper_most : left_most
  end

  def empty?
    @sorted_array.empty?
  end

  private

  def sort
    @sorted_array = ul_placement? ? sort_by_length : sort_by_width
  end

  def left_most
    @sorted_array.pop
  end

  def upper_most
    @sorted_array.pop
  end

  def ul_placement?
    @placement.eql? 'UL'
  end

  def sort_by_width
    @areas_array.sort_by { |area| [area.begin_cursor.width, area.begin_cursor.length] }.reverse
  end

  def sort_by_length
    @areas_array.sort_by { |area| [area.begin_cursor.length, area.begin_cursor.width] }.reverse
  end
end
class Area
  attr_accessor :begin_cursor, :end_cursor, :border_areas, :fitted_sides, :length, :width, :name

  def initialize(begin_cursor, end_cursor, fitted_sides={}, border_areas=[])
    @name = '%s %s' % [begin_cursor, end_cursor]
    @begin_cursor = begin_cursor
    @end_cursor = end_cursor
    @width = @begin_cursor.width..@end_cursor.width
    @length = @begin_cursor.length..@end_cursor.length
    # @sides = { top: , bottom: @begin_cursor.width..@end_cursor.width,
    #           left: @begin_cursor.length..@end_cursor.length, right:  }
    @border_areas = border_areas
    @fitted_sides = fitted_sides
    @side_is_fitted = Hash.new
  end

  def crossing?(other_area)
    (other_area.width.cover?(@width.begin) || other_area.width.cover?(@width.end)) &&
        (other_area.length.cover?(@length.begin) || other_area.length.cover?(@length.end))
  end

  def can_be_merge?(other_area)
    (other_area.width.cover?(@width.begin) && other_area.width.cover?(@width.end)) &&
        (other_area.length.cover?(@length.begin) && other_area.length.cover?(@length.end))
  end

  def try_put_vehicle_in_cross_area(veh_area, area)
    # veh_end_cursor = CellCursor.new(@begin_cursor.width + veh_area.width, @begin_cursor.length + veh_area.length)
    # veh_area = Area.new(@begin_cursor, veh_end_cursor)
    if area.crossing?(veh_area)
      width_begin_cover = area.width.cover?(veh_area.width.begin)
      width_end_cover = area.width.cover?(veh_area.width.end)
      length_begin_cover = area.length.cover?(veh_area.length.begin)
      length_end_cover = area.length.cover?(veh_area.length.end)
      width_begin = width_begin_cover ? veh_area.width.begin : area.width.begin
      width_end = width_end_cover ? veh_area.width.end : area.width.end
      length_begin = length_begin_cover ? veh_area.length.begin : area.length.begin
      length_end = length_end_cover ? veh_area.length.end : area.length.end
      area.put_vehicle(CellCursor.new(width_begin, length_begin), CellCursor.new(width_end, length_end))
    else
      Hash.new
    end
  end

  def put_vehicle(veh_area)
    # TODO fix override
    veh_begin_cursor, veh_end_cursor = veh_area.begin_cursor, veh_area.end_cursor
    @new_areas = Hash.new
    unless veh_begin_cursor.width == @begin_cursor.width
      push_new_area(@begin_cursor.deep_dup, CellCursor.new(veh_begin_cursor.width-1, @end_cursor.length),
                          { right: [veh_begin_cursor.length..veh_end_cursor.length] } )
    end
    unless veh_end_cursor.length == @end_cursor.length
      push_new_area(CellCursor.new(@begin_cursor.width, veh_end_cursor.length+1), @end_cursor.deep_dup,
                          { top: [veh_begin_cursor.width..veh_end_cursor.width] } )
    end
    unless veh_end_cursor.width == @end_cursor.width
      push_new_area(CellCursor.new(veh_end_cursor.width+1, @begin_cursor.length), @end_cursor.deep_dup,
                          { left: [veh_begin_cursor.length..veh_end_cursor.length] } )
    end
    unless veh_begin_cursor.length == @begin_cursor.length
      push_new_area(@begin_cursor.deep_dup, CellCursor.new(@end_cursor.width, veh_begin_cursor.length-1),
                    { top: [veh_begin_cursor.width..veh_end_cursor.width] } )
    end
    # veh_area = Area.new(veh_begin_cursor, veh_end_cursor)
    @border_areas.each do |area|
      @new_areas.merge! try_put_vehicle_in_cross_area(veh_area, area)
    end
    find_border_area
    @new_areas.values
  end

  private

  def push_new_area(begin_cursor, end_cursor, fitted_sides)
    new_area = Area.new(begin_cursor, end_cursor, fitted_sides)
    @new_areas[new_area.name] = new_area
    # @border_areas.each do |border_area|
    #   new_area.border_areas.push(border_area) if new_area.crossing?(border_area)
    # end
  end

  def find_border_area
    @new_areas.each_pair do |name_top, area_top|
      @new_areas.each_pair do |name_sub, area_sub|
        area_top.border_areas.push(area_sub) if !name_top.eql?(name_sub) && area_top.crossing?(area_sub)
      end
    end
  end

  def merge
    # merged_areas = @new_areas.deep_dup
    @new_areas.each_pair do |name_top, area_top|
      @new_areas.each_pair do |name_sub, area_sub|
        if !name_top.eql?(name_sub) && area_top.can_be_merge?(area_sub)
          @new_areas.delete(name_sub)
        end
      end
    end
  end

  # def check_fitted_side
  #   fitted_sides.each_pair do |side_name, fitted_ranges|
  #     (fitted_ranges.length-1).times.each do |i|
  #       if fitted_ranges[i].end + 1 != fitted_ranges[i+1].begin
  #         @side_is_fitted[side_name] = FALSE
  #         next
  #       end
  #     end
  #     if (fitted_ranges[0].begin..fitted_ranges[-1].end).cover?(@sides[side_name])
  #       @side_is_fitted[side_name] = TRUE
  #     end
  #   end
  # end
end
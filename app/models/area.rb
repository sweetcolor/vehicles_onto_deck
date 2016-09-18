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

  def inspect
    '[%s, %s]' % [@width, @length]
  end

  def to_s
    inspect
  end

  def area_contains_cursor?(cursor)
    @width.cover?(cursor.width) && @length.cover?(cursor.length)
  end

  def crossing?(other_area)
    ((@width.cover?(other_area.width.begin) || @width.cover?(other_area.width.end))) &&
        (@length.cover?(other_area.length.begin) || @length.cover?(other_area.length.end)) ||
    ((other_area.width.cover?(@width.begin) || other_area.width.cover?(@width.end))) &&
        (other_area.length.cover?(@length.begin) || other_area.length.cover?(@length.end))
  end

  def override?(other_area)
    (@width.cover?(other_area.width.begin) && @width.cover?(other_area.width.end)) &&
        (@length.cover?(other_area.length.begin) && @length.cover?(other_area.length.end))
  end

  def try_put_vehicle_in_cross_area(veh_area, area, areas_hash, passed_areas)
    # veh_end_cursor = CellCursor.new(@begin_cursor.width + veh_area.width, @begin_cursor.length + veh_area.length)
    # veh_area = Area.new(@begin_cursor, veh_end_cursor)
    if area.crossing?(veh_area)
      length_begin, length_end, width_begin, width_end = area.determine_vehicle_area(veh_area)
      veh_area = Area.new(CellCursor.new(width_begin, length_begin), CellCursor.new(width_end, length_end))
      area.put_vehicle(veh_area, areas_hash, passed_areas)
    else
      { new_areas: Hash.new, old_areas: Hash.new }
    end
  end

  def determine_vehicle_area(other_area)
    width_begin_cover = @width.cover?(other_area.width.begin)
    width_end_cover = @width.cover?(other_area.width.end)
    length_begin_cover = @length.cover?(other_area.length.begin)
    length_end_cover = @length.cover?(other_area.length.end)
    width_begin = width_begin_cover ? other_area.width.begin : @width.begin
    width_end = width_end_cover ? other_area.width.end : @width.end
    length_begin = length_begin_cover ? other_area.length.begin : @length.begin
    length_end = length_end_cover ? other_area.length.end : @length.end
    return length_begin, length_end, width_begin, width_end
  end

  def remove_areas_crossing_veh_area(veh_area, areas_hash)
    after_remove_areas = Hash.new
    @new_areas.each_pair do |name, area|
      # if area.crossing?(veh_area)
      #   after_put_veh_areas = area.put_vehicle(veh_area, areas_hash)
      #   after_remove_areas.merge!(after_put_veh_areas)
      # else
      if area.crossing?(veh_area)
        new_areas = determine_outside_vehicle_area(veh_area, area)
        after_remove_areas.merge!(new_areas)
      else
        after_remove_areas[name] = area
      end
    end
    @new_areas = after_remove_areas
  end

  def put_vehicle(veh_area, areas_hash, passed_areas=Set.new)
    @new_areas = Hash.new
    @old_areas = Hash.new
    unless passed_areas.include?(@name)
      passed_areas.add(@name)

      @new_areas = determine_outside_vehicle_area(veh_area, self)
      # veh_area = Area.new(veh_begin_cursor, veh_end_cursor)
      @old_areas[@name] = self
      @border_areas.each do |name|
        unless passed_areas.include?(name)
          areas_hash[name].border_areas.delete(@name)
          areas_after_putting_vehicle = try_put_vehicle_in_cross_area(veh_area, areas_hash[name], areas_hash, passed_areas)
          if areas_after_putting_vehicle[:new_areas].empty?
            areas_after_putting_vehicle[:new_areas][name] = areas_hash[name]
          else
            areas_after_putting_vehicle[:old_areas][name] = areas_hash[name]
          end
          @new_areas.merge!(areas_after_putting_vehicle[:new_areas])
          @old_areas.merge!(areas_after_putting_vehicle[:old_areas])
        end
      end
      remove_areas_crossing_veh_area(veh_area, areas_hash)
      remove_overridden
      find_border_area
      # merge_areas
      # remove_overridden
    end
    { new_areas: @new_areas, old_areas: @old_areas }
  end

  def determine_outside_vehicle_area(veh_area, area)
    new_areas = Hash.new
    veh_begin_cursor, veh_end_cursor = veh_area.begin_cursor, veh_area.end_cursor
    area_begin_cursor, area_end_cursor  = area.begin_cursor, area.end_cursor
    unless veh_begin_cursor.width == area_begin_cursor.width
      push_new_area(new_areas, area_begin_cursor.deep_dup, CellCursor.new(veh_begin_cursor.width-1, area_end_cursor.length),
                    {right: [veh_begin_cursor.length..veh_end_cursor.length]})
    end
    unless veh_end_cursor.length == area_end_cursor.length
      push_new_area(new_areas, CellCursor.new(area_begin_cursor.width, veh_end_cursor.length+1), area_end_cursor.deep_dup,
                    {top: [veh_begin_cursor.width..veh_end_cursor.width]})
    end
    unless veh_end_cursor.width == area_end_cursor.width
      push_new_area(new_areas, CellCursor.new(veh_end_cursor.width+1, area_begin_cursor.length), area_end_cursor.deep_dup,
                    {left: [veh_begin_cursor.length..veh_end_cursor.length]})
    end
    unless veh_begin_cursor.length == area_begin_cursor.length
      push_new_area(new_areas, area_begin_cursor.deep_dup, CellCursor.new(area_end_cursor.width, veh_begin_cursor.length-1),
                    {top: [veh_begin_cursor.width..veh_end_cursor.width]})
    end
    new_areas
  end

  private

  def push_new_area(new_areas, begin_cursor, end_cursor, fitted_sides)
    new_area = Area.new(begin_cursor, end_cursor, fitted_sides)
    new_areas[new_area.name] = new_area
    # @border_areas.each do |border_area|
    #   new_area.border_areas.push(border_area) if new_area.crossing?(border_area)
    # end
  end

  def find_border_area
    border_areas = Set.new
    @new_areas.each_pair do |name_top, area_top|
      @new_areas.each_pair do |name_sub, area_sub|
        if !name_top.eql?(name_sub) && area_top.crossing?(area_sub)
          border_areas.add(name_sub)
        end
      end
      area_top.border_areas = border_areas.to_a
      border_areas.clear
    end
  end

  def remove_overridden
    # merged_areas = @new_areas.deep_dup
    @new_areas.values.each do |area_top|
      @new_areas.values.each do |area_sub|
        if !area_top.name.eql?(area_sub.name) && area_top.override?(area_sub)
          @new_areas.delete(area_sub.name)
        end
      end
    end
  end

  # def merge_areas
  #   merged_areas = Hash.new
  #   @new_areas.each_pair do |name_top, area_top|
  #     @new_areas.each_pair do |name_sub, area_sub|
  #       unless name_top.eql?(name_sub)
  #         if area_top.can_be_merge_by_width?(area_sub)
  #           length_begin_cover = area_top.length.cover?(area_sub.length.begin)
  #           length_end_cover = area_top.length.cover?(area_sub.length.end)
  #
  #           length_begin = length_begin_cover ? area_sub.length.begin : area_top.length.begin
  #           length_end = length_end_cover ? area_sub.length.end : area_top.length.end
  #           width_begin, width_end  = area_top.width.end+1 == area_sub.width.begin ?
  #               [area_top.width.begin, area_sub.width.end] : [area_sub.width.begin, area_top.width.end]
  #
  #           merged_area = Area.new(CellCursor.new(width_begin, length_begin), CellCursor.new(width_end, length_end))
  #           merged_areas[merged_area.name] = merged_area
  #         elsif area_top.can_be_merge_by_length?(area_sub)
  #           width_begin_cover = area_top.width.cover?(area_sub.width.begin)
  #           width_end_cover = area_top.width.cover?(area_sub.width.end)
  #
  #           width_begin = width_begin_cover ? area_sub.width.begin : area_top.width.begin
  #           width_end = width_end_cover ? area_sub.width.end : area_top.width.end
  #           length_begin, length_end  = area_top.length.end+1 == area_sub.length.begin ?
  #               [area_top.length.begin, area_sub.length.end] : [area_sub.length.begin, area_top.length.end]
  #           merged_area = Area.new(CellCursor.new(width_begin, length_begin), CellCursor.new(width_end, length_end))
  #           merged_areas[merged_area.name] = merged_area
  #         end
  #       end
  #     end
  #   end
  #   @new_areas.merge!(merged_areas)
  # end

  # def can_be_merge_by_width?(other_area)
  #   (end_cursor.width + 1 == other_area.begin_cursor.width || other_area.end_cursor.width + 1 == begin_cursor.width) &&
  #       (length.cover?(other_area.begin_cursor.length) || other_area.length.cover?(begin_cursor.length) ||
  #           length.cover?(other_area.end_cursor.length) || other_area.length.cover?(end_cursor.length))
  # end
  #
  # def can_be_merge_by_length?(other_area)
  #   (end_cursor.length + 1 == other_area.begin_cursor.length || other_area.end_cursor.length + 1 == begin_cursor.length) &&
  #       (width.cover?(other_area.begin_cursor.width) || other_area.length.cover?(begin_cursor.width) ||
  #           width.cover?(other_area.end_cursor.width) || other_area.length.cover?(end_cursor.width))
  # end

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
class Area
  attr_accessor :begin_cursor, :end_cursor, :crossed_areas, :fitted_sides, :length, :width, :name, :only_for_lower_stop

  def initialize(begin_cursor, end_cursor, only_for_lower_stop=nil)
    @begin_cursor = begin_cursor
    @end_cursor = end_cursor
    @width = @begin_cursor.width..@end_cursor.width
    @length = @begin_cursor.length..@end_cursor.length
    @crossed_areas = []
    @only_for_lower_stop = only_for_lower_stop
    @name = '[%s, %s]' % [@width, @length]
  end

  def inspect
    @name
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

  def try_put_vehicle_in_cross_area(veh_area, areas_hash, passed_areas=Set.new)
    if crossing?(veh_area)
      length_begin, length_end, width_begin, width_end = determine_vehicle_area(veh_area)
      veh_area = Area.new(CellCursor.new(width_begin, length_begin), CellCursor.new(width_end, length_end))
      put_vehicle(veh_area, areas_hash, passed_areas)
    else
      { new_areas: Hash.new, old_areas: Hash.new }
    end
  end

  def put_vehicle(veh_area, areas_hash, passed_areas=Set.new)
    @new_areas = Hash.new
    @old_areas = Hash.new
    unless passed_areas.include?(@name)
      passed_areas.add(@name)
      @new_areas = determine_outside_vehicle_area(veh_area, self)
      @old_areas[@name] = self
      @crossed_areas.each do |name|
        unless passed_areas.include?(name)
          areas_hash[name].crossed_areas.delete(@name)
          areas_after_putting_vehicle = areas_hash[name].try_put_vehicle_in_cross_area(veh_area, areas_hash, passed_areas)
          if areas_after_putting_vehicle[:new_areas].empty?
            areas_after_putting_vehicle[:new_areas][name] = areas_hash[name]
          else
            areas_after_putting_vehicle[:old_areas][name] = areas_hash[name]
          end
          @new_areas.merge!(areas_after_putting_vehicle[:new_areas])
          @old_areas.merge!(areas_after_putting_vehicle[:old_areas])
        end
      end
      remove_areas_crossing_veh_area(veh_area)
      remove_overridden
    end
    { new_areas: @new_areas, old_areas: @old_areas }
  end

  private

  def remove_areas_crossing_veh_area(veh_area)
    after_remove_areas = Hash.new
    @new_areas.each_pair do |name, area|
      if area.crossing?(veh_area)
        new_areas = determine_outside_vehicle_area(veh_area, area)
        after_remove_areas.merge!(new_areas)
      else
        after_remove_areas[name] = area
      end
    end
    @new_areas = after_remove_areas
  end

  def determine_outside_vehicle_area(veh_area, area)
    new_areas = Hash.new
    veh_begin_cursor, veh_end_cursor = veh_area.begin_cursor, veh_area.end_cursor
    area_begin_cursor, area_end_cursor  = area.begin_cursor, area.end_cursor
    if veh_begin_cursor.width > area_begin_cursor.width # left
      push_new_area(new_areas, area_begin_cursor.deep_dup, CellCursor.new(veh_begin_cursor.width-1, area_end_cursor.length))
    end
    if veh_end_cursor.length < area_end_cursor.length # bottom
      push_new_area(new_areas, CellCursor.new(area_begin_cursor.width, veh_end_cursor.length+1), area_end_cursor.deep_dup)
    end
    if veh_end_cursor.width < area_end_cursor.width # right
      push_new_area(new_areas, CellCursor.new(veh_end_cursor.width+1, area_begin_cursor.length), area_end_cursor.deep_dup)
    end
    if veh_begin_cursor.length > area_begin_cursor.length # top
      push_new_area(new_areas, area_begin_cursor.deep_dup,
                    CellCursor.new(area_end_cursor.width, veh_begin_cursor.length-1), veh_area.only_for_lower_stop)
    end
    new_areas
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

  def push_new_area(new_areas, begin_cursor, end_cursor, stop=nil)
    new_area = Area.new(begin_cursor, end_cursor, stop)
    new_areas[new_area.name] = new_area
  end

  def remove_overridden
    @new_areas.values.each do |area_top|
      @new_areas.values.each do |area_sub|
        if !area_top.name.eql?(area_sub.name) && area_top.override?(area_sub)
          @new_areas.delete(area_sub.name)
        end
      end
    end
  end
end
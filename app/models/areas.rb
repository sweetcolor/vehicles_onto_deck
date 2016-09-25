class Areas
  attr_reader :areas_array, :areas_hash

  def initialize(areas_array, placement)
    @areas_array = areas_array
    @areas_hash = areas_array.reduce({}) { |hash, area| hash[area.name] = area; hash }
    @placement = placement
    @sorted_array = sort_areas
  end

  def reset(new_areas, old_areas)
    @areas_hash = @areas_hash.delete_if { |key| old_areas.has_key?(key) }.merge(new_areas)
    find_border_area
    keys = @areas_hash.keys
    keys.each do |key|
      @areas_hash[key].crossed_areas = sort_border_name_areas(
          @areas_hash[key],
          @areas_hash[key].crossed_areas.delete_if do |border_area_key|
            !@areas_hash.has_key?(border_area_key)
          end
      )
    end
    @areas_array = @areas_hash.values
    @sorted_array = sort_areas
  end

  def any_fitted?(not_fitted)
    !(areas_array.to_set - not_fitted).empty?
  end

  def get_next
    @sorted_array.pop
  end

  def empty?
    @sorted_array.empty?
  end

  def find_area(begin_cursor)
    contains_beg_cur_areas = Array.new
    areas_array.each do |area|
      contains_beg_cur_areas << area if area.area_contains_cursor?(begin_cursor)
    end
    sort_areas(contains_beg_cur_areas).pop
  end

  private

  def find_border_area
    crossed_areas = Set.new
    @areas_hash.each_pair do |name_top, area_top|
      @areas_hash.each_pair do |name_sub, area_sub|
        if !name_top.eql?(name_sub) && area_top.crossing?(area_sub)
          crossed_areas.add(name_sub)
        end
      end
      area_top.crossed_areas = crossed_areas.to_a
      crossed_areas.clear
    end
  end

  def sort_areas(arr=nil)
    arr = arr.nil? ? @areas_array : arr
    ul_placement? ? sort_by_length(arr) : sort_by_width(arr)
  end

  def sort_border_name_areas(area, border_arr)
    ul_placement? ? sort_border_name_by_length(area, border_arr) : sort_border_name_by_width(area, border_arr)
  end

  def sort_border_name_by_width(area, border_arr)
    border_arr.sort_by do |name|
      [(area.begin_cursor.width - @areas_hash[name].begin_cursor.width).abs,
       (area.begin_cursor.length - @areas_hash[name].begin_cursor.length).abs]
    end
  end

  def sort_border_name_by_length(area, border_arr)
    border_arr.sort_by do |name|
      [(area.begin_cursor.length - @areas_hash[name].begin_cursor.length).abs,
       (area.begin_cursor.width - @areas_hash[name].begin_cursor.width).abs]
    end
  end

  def ul_placement?
    @placement.eql? 'UL'
  end

  def sort_by_width(arr)
    arr.sort_by { |area| [area.begin_cursor.width, area.begin_cursor.length] }.reverse
  end

  def sort_by_length(arr)
    arr.sort_by { |area| [area.begin_cursor.length, area.begin_cursor.width] }.reverse
  end
end
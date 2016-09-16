class Areas
  attr_reader :areas_array, :areas_hash

  def initialize(areas_array, placement)
    @areas_array = areas_array
    @areas_hash = areas_array.reduce({}) { |hash, area| hash[area.name] = area; hash }
    @placement = placement
    sort
    # @sorted_by_width = sort_by_width
    # @sorted_by_length = sort_by_length
  end

  def reset(new_areas, old_areas)
    @areas_hash = @areas_hash.delete_if { |key| old_areas.has_key?(key) }.merge(new_areas)
    keys = @areas_hash.keys
    keys.each do |key|
      @areas_hash[key].border_areas = @areas_hash[key].border_areas.delete_if do |border_area_key|
        !@areas_hash.has_key?(border_area_key)
      end
    end
    @areas_array = @areas_hash.values
    # unless new_areas.empty?
    #   @areas_array = new_areas + @sorted_array
    # end
    sort
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

  private

  def sort
    @sorted_array = ul_placement? ? sort_by_length : sort_by_width
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
class Deck
  attr_reader :max_height, :length, :width, :cells, :vehicles_position, :vehicles_location, :lane_line,
              :exception_colour, :max_quantity_by_width, :max_quantity_by_length
  attr_accessor :special_height_cell_colour, :vehicles, :std_colour

  def initialize(length, width, lane_line)
    @length = length
    @width = width
    @lane_line = lane_line
    @cells = nil
    @max_height = 0

    @vehicles_position = Array.new
    @vehicles_location = Hash.new
    @max_quantity_by_width = 0
    @max_quantity_by_length = 0

    @special_height_cell_colour = nil
    @vehicles = Set.new
    @std_colour = [255,255,255]
    @exception_colour = Hash.new
  end

  def to_s
    inspect
  end

  def inspect
    '[[%s, %s]]' % [@width, @length]
  end

  def make_deck_cells(std_height, exception_height, vis)
    @max_height = exception_height.empty? ? std_height : [std_height, exception_height.keys.max].max
    @std_colour = @special_height_cell_colour[std_height][:colour] if vis && @special_height_cell_colour.include?(std_height)
    cells = Array.new(@length) {
      Array.new(@width, Cell.new({ height: std_height, name: std_height, filled: FALSE}))
    }
    exception_height.each_pair do |key, val|
      val[:length].each do |i|
        val[:width].each do |j|
          cells[i][j] = Cell.new({ height: key, name: key, filled: FALSE })
          if vis && @special_height_cell_colour.include?(key)
            @exception_colour[key] = val
            @exception_colour[key][:colour] = @special_height_cell_colour[key][:colour]
          end
        end
      end
    end
    @cells = cells.deep_dup
  end

  def check_fit_vehicle_onto_deck(vehicle, veh_area, area)
    small_height_end_cursor = CellCursor.new(-1, -1)
    too_high = FALSE
    fitted = TRUE
    if area.length.size >= vehicle.length && area.width.size >= vehicle.width
      veh_area.length.each do |i|
        veh_area.width.each do |j|
          # if @cells[i][j].filled
          #   fitted = FALSE
          # elsif @cells[i][j].height < vehicle.height
          if @cells[i][j].height < vehicle.height
            too_high = TRUE
            small_height_end_cursor = CellCursor.new(j, i)
            fitted = FALSE
          end
        end
      end
    else
      fitted = FALSE
    end
    { fitted: fitted, small_height_end_cursor: small_height_end_cursor, too_high: too_high }
  end

  def prepare_to_drawing
    sort_vehicles_position
    max_quantity_veh_in_row_or_col
  end

  def sort_vehicles_position
    @vehicles_position.sort_by! { |v| [v[:area].begin_cursor.length, v[:area].begin_cursor.width] }
  end

  def put_vehicle_onto_deck(vehicle, veh_area)
    veh_area.length.each do |i|
      veh_area.width.each do |j|
        @cells[i][j].name = vehicle.name
        @cells[i][j].filled = TRUE
      end
    end
    veh_beg_cur = veh_area.begin_cursor
    veh_end_cur = veh_area.end_cursor
    range = {width: veh_beg_cur.width..veh_end_cur.width, length: veh_beg_cur.length..veh_end_cur.length }
    @vehicles_location[vehicle.name] = Array.new unless @vehicles_location.has_key?(vehicle.name)
    @vehicles_location[vehicle.name] << range
    # @vehicles_location[vehicle.name] = Hash.new unless @vehicles_location.has_key?(vehicle.name)
    # @vehicles_location[vehicle.name][range] = FALSE
    @vehicles_position << {vehicle: vehicle, area: veh_area, aligned_to_left: aligned_to_left(veh_area),
                           aligned_to_top: aligned_to_top(veh_area) } if @vehicles.include?(vehicle.name)
  end

  def aligned_to_top(veh_area)
    veh_area.length.begin.zero?
  end

  def aligned_to_left(veh_area)
    veh_area.width.begin.zero?
  end

  def max_quantity_veh_in_row_or_col
    max_quantity_by_length = 0
    max_quantity_by_width = 0
    @vehicles_position.each_with_index do |curr_veh, i|
      quantity_by_width = 1
      quantity_by_length = 1
      top_length = curr_veh[:area].length
      top_width = curr_veh[:area].width
      quantities = quantity_veh_in_row_or_col(
          get_all_without(@vehicles_position, i), max_quantity_by_length, max_quantity_by_width, quantity_by_length,
          quantity_by_width, top_length, top_width
      )
      quantity_by_length = quantities[:by_length]
      quantity_by_width = quantities[:by_width]
      max_quantity_by_length = quantity_by_length if quantity_by_length > max_quantity_by_length
      max_quantity_by_width = quantity_by_width if quantity_by_width > max_quantity_by_width
    end
    @max_quantity_by_length = max_quantity_by_length
    @max_quantity_by_width = max_quantity_by_width
  end

  def get_all_without(array, index)
    # prev_part = index.zero? ? [] : array[0..index-1]
    # next_part = index == array.length-1 ? [] : array[index+1..-1]
    index == array.length-1 ? [] : array[index+1..-1]
    # prev_part + next_part
  end

  def quantity_veh_in_row_or_col(veh_positions, max_quantity_by_l, max_quantity_by_w, quantity_by_length, quantity_by_width, top_length, top_width)
    veh_positions.each_with_index do |veh, i|
      sub_length = veh[:area].length
      sub_width = veh[:area].width
      if side_in_same_row_or_col(top_length, sub_length) && !side_in_same_row_or_col(top_width, sub_width)
        quantity_by_width += 1
        max_quantity_by_l = quantity_veh_in_row_or_col(
            get_all_without(veh_positions, i), max_quantity_by_l, max_quantity_by_w, quantity_by_length,
            quantity_by_width, find_cross_part_of_sides(top_length, sub_length), top_width
        )[:by_length]
      end
      if !side_in_same_row_or_col(top_length, sub_length) && side_in_same_row_or_col(top_width, sub_width)
        quantity_by_length += 1
        max_quantity_by_w = quantity_veh_in_row_or_col(
            get_all_without(veh_positions, i), max_quantity_by_l, max_quantity_by_w, quantity_by_length,
            quantity_by_width, top_length, find_cross_part_of_sides(top_width, sub_width)
        )[:by_width]
      end
      max_quantity_by_l = quantity_by_length if quantity_by_length > max_quantity_by_l
      max_quantity_by_w = quantity_by_width if quantity_by_width > max_quantity_by_w
    end
    { by_length: max_quantity_by_l, by_width: max_quantity_by_w }
  end

  def side_in_same_row_or_col(first_side, second_side)
    first_side.cover?(second_side.begin) || first_side.cover?(second_side.end) ||
        second_side.cover?(first_side.begin) || second_side.cover?(first_side.end)
  end

  def find_cross_part_of_sides(first_side, second_side)
    new_side_begin = first_side.cover?(second_side.begin) ? second_side.begin : first_side.begin
    new_side_end = first_side.cover?(second_side.end) ? second_side.end : first_side.end
    new_side_begin..new_side_end
  end

  def method_missing(name, *args)
    @cells.send(name, *args)
  end
end
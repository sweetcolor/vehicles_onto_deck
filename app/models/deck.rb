class Deck
  attr_reader :max_height, :length, :width, :cells, :vehicles_position, :vehicles_location, :lane_line, :exception_colour
  attr_accessor :special_height_cell_colour, :vehicles, :std_colour

  def initialize(length, width, lane_line)
    @length = length
    @width = width
    @lane_line = lane_line
    @cells = nil
    @colour_cells = nil
    @max_height = 0
    @vehicles_position = Array.new
    @vehicles_location = Hash.new
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
    @max_height = [std_height, exception_height.keys.max].max
    @std_colour = @special_height_cell_colour[std_height][:colour] if vis && @special_height_cell_colour.include?(std_colour)
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
    # not_enough_free_space = FALSE
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
    # { fitted: fitted, small_height_end_cursor: small_height_end_cursor, not_enough_free_space: not_enough_free_space }
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
    @vehicles_location[vehicle.name] = Hash.new unless @vehicles_location.has_key?(vehicle.name)
    @vehicles_location[vehicle.name][range] = FALSE
    @vehicles_position << {vehicle: vehicle, area: veh_area } if @vehicles.include?(vehicle.name)
  end

  def method_missing(name, *args)
    @cells.send(name, *args)
  end
end
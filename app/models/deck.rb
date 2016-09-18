class Deck
  attr_reader :max_height, :length, :width, :cells, :vehicles_location

  def initialize(length, width)
    @length = length
    @width = width
    @cells = nil
    @max_height = 0
    @vehicles_location = Hash.new
  end

  def to_s
    inspect
  end

  def inspect
    '[[%s, %s]]' % [@width, @length]
  end

  def make_deck_cells(std_height, exception_height)
    @max_height = [std_height, exception_height.values.max].max
    cells = Array.new(@length) {
      Array.new(@width, Cell.new({ height: std_height, name: std_height, filled: FALSE }))
    }
    exception_height.each_pair do |key, val|
      key[:width].each { |i| key[:length].each { |j| cells[i][j] = Cell.new({ height: val, name: val, filled: FALSE }) } }
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
  end

  def method_missing(name, *args)
    @cells.send(name, *args)
  end
end
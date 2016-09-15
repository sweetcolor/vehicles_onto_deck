class Deck
  attr_reader :max_height, :length, :width, :cells

  def initialize(length, width)
    @length = length
    @width = width
    @cells = nil
    @max_height = 0
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
          # TODO override
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
    # range = { width: @cursor[:width]..@end_cursor[:width], length: @cursor[:length]..@end_cursor[:length] }
    # @vehicles_location[vehicle_name] = Hash.new unless @vehicles_location.has_key?(vehicle_name)
    # @vehicles_location[vehicle_name][range] = FALSE
  end

  def method_missing(name, *args)
    @cells.send(name, *args)
  end
end
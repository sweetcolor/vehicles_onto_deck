class Deck
  attr_reader :max_height, :length, :width, :vehicles_position, :lane_line, :exception_colour, :std_colour
  attr_accessor :special_height_cell_colour, :vehicles

  def initialize(length, width, lane_line)
    @length = length
    @width = width
    @lane_line = lane_line
    @max_height = 0

    @vehicles_position = Hash.new

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
    @max_height = exception_height.empty? ? std_height : [std_height, exception_height.values.max].max
    @std_colour = @special_height_cell_colour[std_height][:colour] if vis && @special_height_cell_colour.include?(std_height)
    if vis
      exception_height.each_pair do |key, val|
        if @special_height_cell_colour.include?(val)
          @exception_colour[key] = { height: val }.merge(key)
          @exception_colour[key][:colour] = @special_height_cell_colour[val][:colour]
        end
      end
    end
  end

  def check_fit_vehicle_onto_deck(vehicle, area)
    { fitted: area.length.size >= vehicle.length && area.width.size >= vehicle.width }
  end

  def put_vehicle_onto_deck(vehicle, veh_area)
    veh_beg_cur = veh_area.begin_cursor
    veh_end_cur = veh_area.end_cursor
    range = {width: veh_beg_cur.width..veh_end_cur.width, length: veh_beg_cur.length..veh_end_cur.length }
    @vehicles_position[vehicle.name] = {
        vehicle: vehicle, area: veh_area, aligned_to_left: aligned_to_left(veh_area), range: range,
        aligned_to_top: aligned_to_top(veh_area)
    } if @vehicles.include?(vehicle.name)
  end

  def aligned_to_top(veh_area)
    veh_area.length.begin.zero?
  end

  def aligned_to_left(veh_area)
    veh_area.width.begin.zero?
  end
end

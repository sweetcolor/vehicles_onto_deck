class MainPageController < ApplicationController
  def initialize
    @cursor = { width: 0, length: 0 }
    @inserted_vehicles = Hash.new
  end

  def index
  end

  def query
    @parsed_query = Parser.new(params[:query]).parse
    @deck = Deck.new(@parsed_query[:deck_length], @parsed_query[:deck_width])
    @deck.make_deck_cells(@parsed_query[:stdmax], @parsed_query[:EX])
    area = Area.new(CellCursor.new(0, 0), CellCursor.new(@deck.width-1, @deck.length-1))
    # area = Area.new(CellCursor.new(0, 0), CellCursor.new(@deck.width, @deck.length), [], {
    #     top: [@deck.width..@deck.width], bottom: [@deck.width..@deck.width],
    #     left: [@deck.length..@deck.length], right: [@deck.length..@deck.length]
    # })
    @areas = Areas.new([area], @parsed_query[:placement])
    # @new_areas = Array.new
    # @new_areas.append({  })
    @vehicles_location = Hash.new
    # @decks_queue = Queue.new
    # @new_sub_decks_list = Array.new
    # if ul_placement?
    #   @top_map = Array.new(@deck.width+1, 0)
    #   @top_map[-1] = @deck.length
    # else
    #   @top_map = Array.new(@deck.length+1, 0)
    #   @top_map[-1] = @deck.width
    # end
    # @decks_queue.push({ length: 0..@deck.length-1, width: 0..@deck.width-1, top_map: @top_map, not_fit: Hash.new })
    fit_vehicles_onto_deck(:rv, lambda { |*argv| insert_real_vehicle(*argv) })
    fit_vehicles_onto_deck(:SV, lambda { |*argv| insert_standard_vehicle(*argv) })
    @answer = real_vehicle_can_be_fitted
  end

  private

  def fit_vehicles_onto_deck(vehicle_type, vehicle_insert_func)
    @inserted_vehicles = @parsed_query[vehicle_type].reduce(@inserted_vehicles) { |h, v| h[v[:name]] = 0; h }
    @vehicles = remove_too_high_vehicle(@parsed_query[vehicle_type])
    new_areas = Array.new
    @vehicles.each do |veh|
      new_areas.clear
      new_areas = vehicle_insert_func.call(new_areas, veh)
      @areas.reset(new_areas)
    end
  end

  def insert_real_vehicle(new_areas, veh)
    while !@areas.empty? && @inserted_vehicles[veh.name].zero?
      new_areas = try_insert_vehicle(new_areas, veh)
    end
    new_areas
  end

  def insert_standard_vehicle(new_areas, veh)
    # TODO insert standard
    until @areas.empty?
      new_areas = try_insert_vehicle(new_areas, veh)
    end
    new_areas
  end

  def try_insert_vehicle(new_areas, veh)
    area = @areas.get_next
    veh_begin_cursor, veh_end_cursor = area.begin_cursor, area.begin_cursor + CellCursor.new(veh.width-1, veh.length-1)
    veh_area = Area.new(veh_begin_cursor, veh_end_cursor)
    result_of_checking = @deck.check_fit_vehicle_onto_deck(veh, veh_area, area)
    if result_of_checking[:fitted]
      @deck.put_vehicle_onto_deck(veh, veh_area)
      new_areas += area.put_vehicle(veh_area)
      @inserted_vehicles[veh.name] += 1
    elsif result_of_checking[:too_high]
      small_height_area = Area.new(veh_begin_cursor, result_of_checking[:small_height_end_cursor])
      new_areas += area.put_vehicle(small_height_area)

      new_areas.push(small_height_area)
    end
    new_areas
  end

  def old_fit_vehicles_onto_deck(vehicle_type, vehicle_insert_func)
    # @parsed_params[vehicle_type].each { |v| @vehicles_location[v[:name]] = Hash.new }
    @inserted_vehicles = @parsed_query[vehicle_type].reduce(@inserted_vehicles) { |h, v| h[v[:name]] = 0; h }
    @vehicles = remove_too_high_vehicle(@parsed_query[vehicle_type])
    is_all_veh_inserted = FALSE
    until @decks_queue.empty? || is_all_veh_inserted && is_real_vehicle?(vehicle_type) do
      @sub_deck = @decks_queue.pop
      @top_map = @sub_deck[:top_map]
      update_cursor
      idx = 0
      while idx < @vehicles.length do
        veh = @vehicles[idx]
        if @sub_deck[:not_fit].has_key?(veh[:name])
          idx += 1
          next
        end
        update_end_cursor(veh)
        is_not_enough_free_space = not_enough_free_space?(veh)
        if is_not_enough_free_space
          idx += 1
          @inserted_vehicles[veh[:name]] -= 1 if @inserted_vehicles[veh[:name]].zero?
        else
          idx = vehicle_insert_func.call(idx, is_not_enough_free_space, veh)
          update_cursor
        end
        is_all_veh_inserted = all_vehicle_inserted?
        if is_all_veh_inserted && is_real_vehicle?(vehicle_type)
          @new_sub_decks_list.unshift(@sub_deck)
          # @new_sub_decks_list.push(@sub_deck)
        end
      end
      merge_sub_decks if @new_sub_decks_list.length > 1
      @new_sub_decks_list.each { |new_sub_deck| @decks_queue.push(new_sub_deck) }
      @new_sub_decks_list.clear
    end
  end

  def merge_sub_decks
    merged_sub_decks_list = Array.new
    merged_sub_decks_indexes = Set.new
    begin
      @new_sub_decks_list.each_with_index do |sub_deck_idx, idx|
        next if merged_sub_decks_indexes.include?(idx)
        @new_sub_decks_list.each_with_index do |sub_deck_j, j|
          next if idx == j
          merged_not_fit = sub_deck_idx[:not_fit].merge(sub_deck_j[:not_fit])
          if sub_deck_idx[:width] == sub_deck_j[:width] && sub_deck_idx[:length].end + 1 == sub_deck_j[:length].begin
              merged_length = sub_deck_idx[:length].begin..sub_deck_j[:length].end
              if ul_placement?
                cursor = get_cursor_from_deck_range(sub_deck_idx)
                end_cursor = get_end_cursor_from_deck_range(sub_deck_j)
                merged_top_map = set_top_map_for_new_sub_deck(end_cursor, cursor)
              else
                sub_deck_idx[:top_map].pop
                merged_top_map = sub_deck_idx[:top_map] + sub_deck_j[:top_map][sub_deck_j[:length]] +
                    sub_deck_j[:top_map][-1]
              end
              merged_sub_decks_list.append({ width: sub_deck_idx[:width], length: merged_length, not_fit: merged_not_fit,
                                             top_map: merged_top_map })
              merged_sub_decks_indexes.add(j)
              merged_sub_decks_indexes.add(idx)
          elsif sub_deck_idx[:length] == sub_deck_j[:length] && sub_deck_idx[:width].end + 1 == sub_deck_j[:width].begin
              merged_width = sub_deck_idx[:width].begin..sub_deck_j[:width].end
              if ul_placement?
                sub_deck_idx[:top_map].pop
                merged_top_map = sub_deck_idx[:top_map] + sub_deck_j[:top_map][sub_deck_j[:width]] +
                    sub_deck_j[:top_map][-1]
              else
                cursor = get_cursor_from_deck_range(sub_deck_idx)
                end_cursor = get_end_cursor_from_deck_range(sub_deck_j)
                merged_top_map = set_top_map_for_new_sub_deck(end_cursor, cursor)
              end
              merged_sub_decks_list.append({ width: merged_width, length: sub_deck_idx[:length], not_fit: merged_not_fit,
                                             top_map: merged_top_map })
              merged_sub_decks_indexes.add(j)
              merged_sub_decks_indexes.add(idx)
          end
        end
      end
      @new_sub_decks_list.each_with_index do |d, i|
        merged_sub_decks_list << d unless merged_sub_decks_indexes.include?(i)
      end
      @new_sub_decks_list = merged_sub_decks_list
      merged_sub_decks_indexes.clear
    end while merged_sub_decks_indexes.size > 0
  end

  def get_end_cursor_from_deck_range(sub_deck)
    { width: sub_deck[:width].end, length: sub_deck[:length].end }
  end

  def get_cursor_from_deck_range(sub_deck)
    { width: sub_deck[:width].begin, length: sub_deck[:length].begin }
  end

  def is_real_vehicle?(curr_veh_type)
    curr_veh_type == :rv
  end

  def all_vehicle_inserted?
    @inserted_vehicles.values.all? { |status| !status.zero? }
  end

  def real_vehicle_can_be_fitted
    @inserted_vehicles.slice(*@parsed_query[:rv].map { |v| v[:name] }).values.all? { |s| !s.zero? }
  end

  def old_insert_real_vehicle(idx, not_enough_space, veh)
    until @inserted_vehicles[veh[:name]] == 1 || not_enough_space do
      idx, not_enough_space = try_insert_vehicle(idx, veh)
    end
    idx
  end

  def old_insert_standard_vehicle(idx, not_enough_space, veh)
    std_idx = idx
    until not_enough_space do
      std_idx, not_enough_space = try_insert_vehicle(std_idx, veh)
    end
    idx += std_idx > 0 ? 1 : 0
    idx
  end

  def old_try_insert_vehicle(idx, veh)
    result_of_checking = check_fit_vehicle_onto_deck(veh)
    if vehicle_fit?(result_of_checking[:in_pit], result_of_checking[:too_high])
      put_vehicle_onto_deck(veh[:name])
      @inserted_vehicles[veh[:name]] += 1
      idx += 1
    else
      if out_of_range? || cursor_in_filled_cell?
        update_cursor
      elsif result_of_checking[:in_pit]
        out_from_pit(result_of_checking[:real_end_cursor], veh)
      elsif result_of_checking[:too_high]
        try_to_find_fitted_vehicle(@vehicles, idx)
        idx += 1
        return idx, FALSE
      end
      if not_enough_free_space?(veh)
        update_cursor
      end
    end
    is_not_enough_free_space = not_enough_free_space?(veh)
    update_end_cursor(veh)
    return idx, is_not_enough_free_space
  end

  def out_from_pit(real_end_cursor, veh)
    top_map = set_top_map_for_new_sub_deck(real_end_cursor)
    width = @cursor[:width]..real_end_cursor[:width]
    length = @cursor[:length]..real_end_cursor[:length]
    not_fit = Hash.new
    not_fit[veh[:name]] = veh
    @new_sub_decks_list.push(
        {width: width, length: length, top_map: top_map, not_fit: not_fit}
    )
    update__top_map(real_end_cursor)
    update_cursor
  end

  def try_to_find_fitted_vehicle(vehicles, too_high_veh_idx)
    if vehicles.length > 1
      (too_high_veh_idx+1..vehicles.length-1).each do |i|
        update_end_cursor(vehicles[i])
        result_of_checking = check_fit_vehicle_onto_deck(vehicles[i])
        if vehicle_fit?(result_of_checking[:in_pit], result_of_checking[:too_high])
          @vehicles = exchange_too_high_vehicle(vehicles, too_high_veh_idx, i)
          return try_insert_vehicle(too_high_veh_idx, @vehicles[too_high_veh_idx])
        end
      end
    end
    update_end_cursor(vehicles[too_high_veh_idx])
    result_of_checking = check_fit_vehicle_onto_deck(vehicles[too_high_veh_idx])
    out_from_pit(result_of_checking[:real_end_cursor], vehicles[too_high_veh_idx])
    vehicles
  end

  def exchange_too_high_vehicle(vehicles, too_high_veh_idx, fitted_veh_idx)
    (too_high_veh_idx.zero? ? [] : vehicles[0..too_high_veh_idx-1]) + [vehicles[fitted_veh_idx], vehicles[too_high_veh_idx]] +
        vehicles[too_high_veh_idx+1..fitted_veh_idx-1] + vehicles[fitted_veh_idx+1..-1]
  end

  def cursor_in_filled_cell?
    @deck[@cursor[:length]][@cursor[:width]][:filled]
  end

  def update_end_cursor(veh)
    @end_cursor = { width: @cursor[:width]+veh[:width]-1, length: @cursor[:length]+veh[:length]-1 }
  end

  def set_top_map_for_new_sub_deck(real_end_cursor, cursor=nil)
    cursor = cursor.nil? ? @cursor : cursor
    if ul_placement?
      top_map = Array.new(real_end_cursor[:width]+2, cursor[:length])
      cursor[:width].times.each { |i| top_map[i] = real_end_cursor[:length] }
      top_map[-1] = real_end_cursor[:length]
    else
      top_map = Array.new(real_end_cursor[:length]+2, cursor[:width])
      cursor[:length].times.each { |i| top_map[i] = real_end_cursor[:width] }
      top_map[-1] = real_end_cursor[:width]
    end
    top_map
  end

  def remove_too_high_vehicle(vehicles)
    height_max = [@parsed_query[:stdmax], @parsed_query[:EX].values.max].max
    vehicles.map { |veh| veh if veh[:height] <= height_max }.compact
  end

  def update_cursor
    top_map__min = @top_map.min
    top_map__index = @top_map.index(top_map__min)
    if ul_placement?
      @cursor[:length], @cursor[:width] = top_map__min, top_map__index
    else
      @cursor[:length], @cursor[:width] = top_map__index, top_map__min
    end
  end

  def vehicle_fit?(in_pit, too_high)
    !in_pit && !too_high
  end

  def out_of_range?
    if ul_placement?
      @cursor[:width] > @sub_deck[:width].end
    else
      @cursor[:length] > @sub_deck[:length].end
    end
  end

  def not_enough_free_space?(vehicle)
    if ul_placement?
      @top_map.min + vehicle[:length] - 1 > @sub_deck[:length].end
    else
      @top_map.min + vehicle[:width] - 1 > @sub_deck[:width].end
    end
  end

  def update__top_map(end_cursor)
    if ul_placement?
      (@cursor[:width]..end_cursor[:width]).each { |i| @top_map[i] = end_cursor[:length] + 1 }
    else
      (@cursor[:length]..end_cursor[:length]).each { |i| @top_map[i] = end_cursor[:width] + 1 }
    end
  end

  def check_fit_vehicle_onto_deck(vehicle)
    real_end_cursor = { width: @end_cursor[:width], length: @end_cursor[:length] }
    in_length = @sub_deck[:length].end >= @end_cursor[:length]
    in_width = @sub_deck[:width].end >= @end_cursor[:width]
    in_pit = FALSE
    too_high = FALSE
    if in_length && in_width
      (@cursor[:length]..@end_cursor[:length]).each do |i|
        (@cursor[:width]..@end_cursor[:width]).each do |j|
          if @deck[i][j][:filled]
            in_pit = TRUE
            real_end_cursor[:width] = j
            real_end_cursor[:length] = i
            if ul_placement?
              real_end_cursor[:width] -= 1
              break
            end
          elsif @deck[i][j][:height] < vehicle[:height]
            real_end_cursor[:width] = j
            real_end_cursor[:length] = i
            too_high = TRUE
            return { real_end_cursor: real_end_cursor, in_pit: in_pit, too_high: too_high  }
          end
        end
        if !ul_placement? && in_pit
          real_end_cursor[:width] -= 1
          break
        end
      end
    else
      real_end_cursor[:width] = in_width ? @end_cursor[:width] : @sub_deck[:width].end
      real_end_cursor[:length] = in_length ? @end_cursor[:length] : @sub_deck[:length].end
      in_pit = TRUE
    end
    { real_end_cursor: real_end_cursor, in_pit: in_pit, too_high: too_high  }
  end

  def put_vehicle_onto_deck(vehicle_name)
    (@cursor[:length]..@end_cursor[:length]).each do |i|
      (@cursor[:width]..@end_cursor[:width]).each do |j|
        @deck[i][j][:name] = vehicle_name
        @deck[i][j][:filled] = TRUE
      end
    end
    range = { width: @cursor[:width]..@end_cursor[:width], length: @cursor[:length]..@end_cursor[:length] }
    @vehicles_location[vehicle_name] = Hash.new unless @vehicles_location.has_key?(vehicle_name)
    @vehicles_location[vehicle_name][range] = FALSE
        # @vehicles_location[@cursor[:width]] = Hash.new unless @vehicles_location.has_key?(@cursor[:width])
    # @vehicles_location[@cursor[:width]][@cursor[:length]] = { width: @cursor[:width] - @end_cursor[:width],
    #                                                           length: @cursor[:length] - @end_cursor[:length],
    #                                                           name: vehicle_name, drawn: FALSE }
    # @vehicles_location[@cursor[:width]] = Hash.new unless @vehicles_location.has_key?(@cursor[:width])
    # @vehicles_location[@cursor[:width]][@cursor[:length]] = { end_cursor: @end_cursor, name: vehicle_name }
    update__top_map(@end_cursor)
    update_cursor
  end

  def ul_placement?
    @parsed_query[:placement] == 'UL'
  end
end

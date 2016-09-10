class MainPageController < ApplicationController
  def initialize
    @cursor = { width: 0, length: 0 }
    @inserted_vehicles = Hash.new
  end

  def index
  end

  def query
    @parsed_params = parse_query
    @cells = make_deck_cells
    @deck = @cells.deep_dup
    @decks_queue = Queue.new
    @new_sub_decks_list = Array.new
    @top_map = Array.new(@deck.first.length+1, 0)
    @top_map[-1] = @deck.length
    @decks_queue.push({ length: 0..@deck.length-1, width: 0..@deck.first.length-1, top_map: @top_map, not_fit: Hash.new })
    fit_vehicles_onto_deck(:rv, lambda { |*argv| insert_real_vehicle(*argv) })
    fit_vehicles_onto_deck(:SV, lambda { |*argv| insert_standard_vehicle(*argv) })
  end

  private

  def parse_query
    url_parameters_hash = Hash.new
    splitted_query = params[:query].split('~').map { |param| param.split('=') }
    splitted_query.map! { |e| e.length != 2 ? e.map { |sub_e| sub_e.split('_') }.flatten : e }
    splitted_query.each do |elem_query|
      url_parameters_hash[elem_query.first.to_sym] = if elem_query.length != 2
                                                       elem_query[1..elem_query.length]
                                                     else
                                                       val = elem_query[elem_query.length-1].split(',').map do |e|
                                                         e =~ /[0-9]/ ? e.to_i : e
                                                       end
                                                       val.length == 1 ? val.first : val
                                                     end
    end
    url_parameters_hash[:rv] = parse_real_vehicle(url_parameters_hash[:rv])
    url_parameters_hash[:EX] = parse_exception_cells(url_parameters_hash[:EX])
    url_parameters_hash[:SV] = parse_standard_vehicle(url_parameters_hash)
    url_parameters_hash
  end

  def parse_standard_vehicle(params)
    sort_vehicle(params.select { |k| k =~ /sv/}).to_a
  end

  def parse_real_vehicle(vehicles)
    sort_vehicle(vehicles.map { |v| v.split(',') }.map { |a| [a[0], a[1..3].map { |e| e.to_i }] })
  end

  def parse_exception_cells(cells)
    cells.map.with_index do |cell, i|
      if i.odd?
        cell.to_i
      else
        [:width, :length].zip([
                                  Range.new(*cell.scan(/[0-9]+/).map { |num| num.to_i - 1 }),
                                  Range.new(*cell.scan(/[A-Z]+/).map { |str| convert_column_name_to_int(str) })
                              ]).to_h
      end
    end.each_slice(2).to_h
  end

  def sort_vehicle(vehicle)
    vehicle.sort_by { |a| a[1] }.map do |a|
      [:name, :width, :length, :height].zip([a[0], *a[1]]).to_h
    end.reverse
  end

  def make_deck_cells
    cells = Array.new(@parsed_params[:deck_length]) {
      Array.new(@parsed_params[:deck_width], { height: @parsed_params[:stdmax], name: @parsed_params[:stdmax], filled: FALSE })
    }
    @parsed_params[:EX].each_pair do |key, val|
      key[:width].each { |i| key[:length].each { |j| cells[i][j] = { height: val, name: val, filled: FALSE } } }
    end
    cells
  end

  def convert_column_name_to_int(name)
    name.downcase.split('').map { |c| c.ord % 'a'.ord }.map.with_index { |pos, i| pos*10**i}.reduce(:+)
  end

  def fit_vehicles_onto_deck(vehicle_type, vehicle_insert_func)
    @inserted_vehicles = @parsed_params[vehicle_type].reduce(@inserted_vehicles) { |h, v| h[v[:name]] = 0; h }
    vehicles = remove_too_high_vehicle(@parsed_params[vehicle_type])
    is_all_veh_inserted = FALSE
    until @decks_queue.empty? || is_all_veh_inserted && is_real_vehicle?(vehicle_type) do
      @sub_deck = @decks_queue.pop
      @top_map = @sub_deck[:top_map]
      update_cursor
      idx = 0
      while idx < vehicles.length do
        veh = vehicles[idx]
        if @sub_deck[:not_fit].has_key?(veh[:name])
          idx += 1
          next
        end
        update_end_cursor(veh)
        is_not_enough_free_space = not_enough_free_space?(veh)
        idx, is_not_enough_free_space = vehicle_insert_func.call(idx, is_not_enough_free_space, veh, vehicles)
        is_all_veh_inserted = all_vehicle_inserted?
        update_cursor
        if is_not_enough_free_space
          idx += 1
          @inserted_vehicles[veh[:name]] -= 1 if @inserted_vehicles[veh[:name]].zero?
        end
        if is_all_veh_inserted && is_real_vehicle?(vehicle_type)
          @new_sub_decks_list.push(@sub_deck)
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
          if sub_deck_idx[:width] == sub_deck_j[:width]
            if sub_deck_idx[:length].end + 1 == sub_deck_j[:length].begin
              merged_length = sub_deck_idx[:length].begin..sub_deck_j[:length].end
              cursor = get_cursor_from_deck_range(sub_deck_idx)
              end_cursor = get_end_cursor_from_deck_range(sub_deck_j)
              merged_sub_decks_list.append({ width: sub_deck_idx[:width], length: merged_length, not_fit: merged_not_fit,
                                             top_map: set_top_map_for_new_sub_deck(end_cursor, cursor) })
              merged_sub_decks_indexes.add(j)
              merged_sub_decks_indexes.add(idx)
            # elsif sub_deck_idx[:length].begin - 1 == @new_sub_decks_list[j][:length].end
            #   merged_length = @new_sub_decks_list[j][:length].begin..sub_deck_idx[j][:length].end
            #   cursor = get_cursor_from_deck_range(@new_sub_decks_list[j])
            #   end_cursor = get_end_cursor_from_deck_range(sub_deck_idx)
            #   merged_sub_decks_list.append({ width: sub_deck_idx[:width], length: merged_length, not_fit: merged_not_fit,
            #                                  top_map: set_top_map_for_new_sub_deck(end_cursor, cursor) })
            end
          elsif sub_deck_idx[:length] == sub_deck_j[:length]
            if sub_deck_idx[:width].end + 1 == sub_deck_j[:width].begin
              merged_width = sub_deck_idx[:width].begin..sub_deck_j[:width].end
              sub_deck_idx[:top_map].pop
              merged_top_map = sub_deck_idx[:top_map] + sub_deck_j[:top_map][sub_deck_j[:width]]
              merged_sub_decks_list.append({ width: merged_width, length: sub_deck_idx[:length], not_fit: merged_not_fit,
                                             top_map: merged_top_map })
              merged_sub_decks_indexes.add(j)
              merged_sub_decks_indexes.add(idx)
            # elsif sub_deck_idx[:width].begin - 1 == @new_sub_decks_list[j][:width].end
            #   merged_width = @new_sub_decks_list[j][:width].begin..sub_deck_idx[j][:width].end
            #   @new_sub_decks_list[j][:top_map].pop
            #   merged_top_map = @new_sub_decks_list[j][:top_map] + sub_deck_idx[:top_map][sub_deck_idx[:width]]
            #   merged_sub_decks_list.append({ width: merged_width, length: sub_deck_idx[:length], not_fit: merged_not_fit,
            #                                  top_map: merged_top_map })
            end
          end
          # if merged_sub_decks_list.length == appended_sub_decks_count
          #   merged_sub_decks_list.append(sub_deck_idx)
            # merged_sub_decks_list.append(sub_deck_j)
          #   appended_sub_decks_count += 1
          # else
          #   appended_sub_decks_count += 1
          # end
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
    {width: sub_deck[:width].begin, length: sub_deck[:length].begin}
  end

  def is_real_vehicle?(curr_veh_type)
    curr_veh_type == :rv
  end

  def all_vehicle_inserted?
    @inserted_vehicles.values.all? { |status| !status.zero? }
  end

  def insert_real_vehicle(idx, is_not_enough_free_space, veh, vehicles)
    until @inserted_vehicles[veh[:name]] > 0 || is_not_enough_free_space do
      idx, is_not_enough_free_space = try_insert_vehicle(idx, veh, vehicles)
    end
    return idx, is_not_enough_free_space
  end

  def insert_standard_vehicle(idx, is_not_enough_free_space, veh, vehicles)
    until is_not_enough_free_space do
      idx, is_not_enough_free_space = try_insert_vehicle(idx, veh, vehicles)
    end
    return idx, is_not_enough_free_space
  end

  def try_insert_vehicle(idx, veh, vehicles)
    real_cursor, real_end_cursor, in_pit = check_fit_vehicle_onto_deck(veh)
    if vehicle_fit?(real_cursor, real_end_cursor, in_pit)
      put_vehicle_onto_deck(veh[:name])
      @inserted_vehicles[veh[:name]] += 1
      idx += 1
    else
      if out_of_range? || cursor_in_filled_cell?
        update_cursor
      elsif in_pit
        top_map = set_top_map_for_new_sub_deck(real_end_cursor)
        width = @cursor[:width]..real_end_cursor[:width]
        length = @cursor[:length]..real_end_cursor[:length]
        not_fit = Hash.new
        not_fit[veh[:name]] = veh
        @new_sub_decks_list.push(
            { width: width, length: length, top_map: top_map, not_fit: not_fit }
        )
        update__top_map(real_end_cursor)
        update_cursor
      elsif vehicle_too_high?(real_cursor)
        # TODO if vehicles[idx] and vehicles[idx+1] too high
        vehicles[idx], vehicles[idx+1] = vehicles[idx+1], vehicles[idx]
        return
      end
      if not_enough_free_space?(veh)
        update_cursor
      end
    end
    is_not_enough_free_space = not_enough_free_space?(veh)
    update_end_cursor(veh)
    return idx, is_not_enough_free_space
  end

  def cursor_in_filled_cell?
    @deck[@cursor[:length]][@cursor[:width]][:filled]
  end

  def update_end_cursor(veh)
    @end_cursor = { width: @cursor[:width]+veh[:width]-1, length: @cursor[:length]+veh[:length]-1 }
  end

  def set_top_map_for_new_sub_deck(real_end_cursor, cursor=nil)
    cursor = cursor.nil? ? @cursor : cursor
    top_map = Array.new(real_end_cursor[:width]+2, cursor[:length])
    cursor[:width].times.each { |i| top_map[i] = real_end_cursor[:length] }
    top_map[-1] = real_end_cursor[:length]
    top_map
  end

  def remove_too_high_vehicle(vehicles)
    height_max = [@parsed_params[:stdmax], @parsed_params[:EX].values.max].max
    vehicles.map { |veh| veh if veh[:height] <= height_max }.compact
  end

  def update_cursor
    top_map__min = @top_map.min
    top_map__index = @top_map.index(top_map__min)
    @cursor[:length] = top_map__min
    @cursor[:width] = top_map__index
  end

  def vehicle_fit?(real_cursor, real_end_cursor, in_pit)
    real_cursor == @cursor && @end_cursor == real_end_cursor && !in_pit
  end

  def out_of_range?
    @cursor[:width] > @sub_deck[:width].end
  end

  def not_enough_free_space?(vehicle)
    @top_map.min + vehicle[:length] - 1 > @sub_deck[:length].end
  end

  def vehicle_in_pit?(real_end_cursor)
    real_end_cursor[:width] < @end_cursor[:width]
  end

  def vehicle_too_high?(real_cursor)
    real_cursor[:width] > @cursor[:width]
  end

  def update__top_map(end_cursor)
    (@cursor[:width]..end_cursor[:width]).each { |i| @top_map[i] = end_cursor[:length] + 1 }
  end

  def check_fit_vehicle_onto_deck(vehicle)
    real_cursor = { width: @cursor[:width], length: @cursor[:length] }
    real_end_cursor = { width: @end_cursor[:width], length: @end_cursor[:length] }
    in_length = @sub_deck[:length].end >= @end_cursor[:length]
    in_width = @sub_deck[:width].end >= @end_cursor[:width]
    in_pit = FALSE
    if in_length && in_width
      (@cursor[:length]..@end_cursor[:length]).each do |i|
        (@cursor[:width]..@end_cursor[:width]).each do |j|
          if @deck[i][j][:filled]
            real_end_cursor[:width] = j - 1
            real_end_cursor[:length] = i
            in_pit = TRUE
            break
          elsif @deck[i][j][:height] < vehicle[:height]
            real_cursor[:width] = j
            real_cursor[:length] = i
            return real_cursor, real_end_cursor, in_pit
          end
        end
      end
    else
      real_end_cursor[:width] = in_width ? @end_cursor[:width] : @sub_deck[:width].end
      real_end_cursor[:length] = in_length ? @end_cursor[:length] : @sub_deck[:length].end
      in_pit = TRUE
    end
    return real_cursor, real_end_cursor, in_pit
  end

  def put_vehicle_onto_deck(vehicle_name)
    (@cursor[:length]..@end_cursor[:length]).each do |i|
      (@cursor[:width]..@end_cursor[:width]).each do |j|
        @deck[i][j][:name] = vehicle_name
        @deck[i][j][:filled] = TRUE
      end
    end
    update__top_map(@end_cursor)
    @cursor[:width] = @end_cursor[:width] + 1
  end
end

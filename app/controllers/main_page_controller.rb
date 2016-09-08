class MainPageController < ApplicationController
  def index
  end

  def query
    @parsed_params = parse_query
    @cells = make_deck_cells
    @deck = @cells.deep_dup
    @vehicles_count = nil
    fit_vehicles_onto_deck
    # fit_all_vehicles_onto_deck(@parsed_params)
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
    sort_vehicle(vehicles.map { |v| v.split(',') }.map do |a|
      name_splitted = a[0].split('%').keep_if { |v| !v.downcase.start_with? 'v' }
      [name_splitted[0..-2].map { |n| n[0].downcase }.join + name_splitted[-1], a[1..3].map { |e| e.to_i }]
    end)
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

  def fit_vehicles_onto_deck
    decks_queue = Queue.new
    new_decks_queue = Queue.new
    decks_queue.push({ length: 0..@deck.length, width: 0..@deck.first.length })
    inserted_vehicles = @parsed_params[:rv].reduce({}) { |h, v| h[v[:name]] = FALSE; h }
    vehicles = remove_too_high_vehicle(@parsed_params[:rv])
    until decks_queue.empty? do
      sub_deck = decks_queue.pop
      top_map = Array.new(sub_deck[:width].end+1, 0)
      top_map[-1] = sub_deck[:length].end
      top_map__min = top_map.min
      cursor = { width: sub_deck[:width].begin, length: sub_deck[:width].begin }
      idx = 0
      while idx < vehicles.length do
        veh = vehicles[idx]
        end_cursor = { width: cursor[:width]+veh[:width], length: cursor[:length]+veh[:length] }
        is_out_of_range = out_of_range?(veh, sub_deck, top_map__min)
        until inserted_vehicles[veh[:name]] || is_out_of_range do
          real_cursor, real_end_cursor = check_fit_vehicle_onto_deck(veh, sub_deck, end_cursor, cursor)
          if vehicle_fit?(cursor, real_cursor, end_cursor, real_end_cursor)
            put_vehicle_onto_deck(veh[:name], end_cursor, cursor, top_map)
            inserted_vehicles[veh[:name]] = TRUE
            idx += 1
          else
            if vehicle_in_pit?(end_cursor, real_end_cursor)
              decks_queue.push(
                  { width: cursor[:width]..real_end_cursor[:width], length: cursor[:length]..real_end_cursor[:length] }
              )
              update__top_map(top_map, cursor, real_end_cursor)
              update_cursor(cursor, top_map)
            elsif vehicle_too_high?(cursor, real_cursor)
              # TODO if vehicles[idx] and vehicles[idx+1] too high
              vehicles[idx], vehicles[idx+1] = vehicles[idx+1], vehicles[idx]
              break
            end
            if out_of_range?(veh, sub_deck, top_map.min)
              update_cursor(cursor, top_map)
            end
          end
          is_out_of_range = out_of_range?(veh, sub_deck, top_map__min)
          end_cursor = { width: cursor[:width]+veh[:width], length: cursor[:length]+veh[:length] }
        end
      end
      decks_queue = new_decks_queue
      new_decks_queue = Queue.new
    end
  end

  def remove_too_high_vehicle(vehicles)
    height_max = [@parsed_params[:stdmax], @parsed_params[:EX].values.max].max
    vehicles.map { |veh| veh if veh[:height] <= height_max }.compact
  end

  def update_cursor(cursor, top_map)
    top_map__index, top_map__min = min_top_map(top_map)
    cursor[:length] = top_map__min
    cursor[:width] = top_map__index
  end

  def vehicle_fit?(cursor, real_cursor, end_cursor, real_end_cursor)
    real_cursor == cursor && end_cursor == real_end_cursor
  end

  # def try_insert_vehicle(veh, sub_deck, end_cursor, cursor, top_map, decks_queue)
  #
  #   inserted_vehicles
  # end

  def out_of_range?(vehicle, sub_deck, top_map__min)
    top_map__min + vehicle[:length] > sub_deck[:length].end
  end

  def vehicle_in_pit?(end_cursor, real_end_cursor)
    real_end_cursor[:width] < end_cursor[:width]
  end

  def vehicle_too_high?(cursor, real_cursor)
    real_cursor[:width] > cursor[:width]
  end

  def update__top_map(top_map, cursor, end_cursor)
    (cursor[:width]..end_cursor[:width]-1).each { |i| top_map[i] = end_cursor[:length] }
  end

  def min_top_map(top_map)
    top_map__min = top_map.min
    top_map__index = top_map.index(top_map__min)
    return top_map__index, top_map__min
  end

  def check_fit_vehicle_onto_deck(vehicle, deck ,end_cursor, cursor)
    real_cursor = { width: cursor[:width], length: cursor[:length] }
    real_end_cursor = { width: end_cursor[:width], length: end_cursor[:length] }
    in_length = deck[:length].end >= end_cursor[:length]
    in_width = deck[:width].end >= end_cursor[:width]
    if in_length && in_width
      (cursor[:length]..end_cursor[:length]-1).each do |i|
        (cursor[:width]..end_cursor[:width]-1).each do |j|
          if @deck[i][j][:filled]
            real_end_cursor[:width] = j + 1
            real_end_cursor[:length] += 1
            break
          elsif @deck[i][j][:height] < vehicle[:height]
            real_cursor[:width] = j + 1
            real_cursor[:length] = i
            return real_cursor, real_end_cursor
          end
        end
      end
    else
      real_end_cursor[:width] = in_width ? end_cursor[:width] : deck[:width].end
      real_end_cursor[:length] = in_length ? end_cursor[:length] : deck[:length].end
    end
    return real_cursor, real_end_cursor
  end

  def put_vehicle_onto_deck(vehicle_name, end_cursor, cursor, top_map)
    (cursor[:length]..end_cursor[:length]-1).each do |i|
      (cursor[:width]..end_cursor[:width]-1).each do |j|
        @deck[i][j][:name] = vehicle_name
        @deck[i][j][:filled] = TRUE
      end
    end
    update__top_map(top_map, cursor, end_cursor)
    cursor[:width] = end_cursor[:width]
  end
end

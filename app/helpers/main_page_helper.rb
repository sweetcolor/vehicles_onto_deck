module MainPageHelper
  DECK_PARAMETERS_ARRAY = %w[deck_width deck_length stdmax EX]
  VEHICLE_PARAMETERS_ARRAY = %w[sv rv sort_order placement]
  ANSWER_PARAMETERS_ARRAY = %w[a LL c]

  def parse_query(query)
    url_parameters_hash = Hash.new
    splitted_query = query.split('~').map { |param| param.split('=') }
    splitted_query.map! { |e| e.length != 2 ? e.map { |sub_e| sub_e.split('_') }.flatten : e }
    splitted_query.each do |elem_query|
      url_parameters_hash[elem_query.first.to_sym] = if elem_query.length != 2
        elem_query[1..elem_query.length]
      else
        val = elem_query[elem_query.length-1].split(',').map { |e| e =~ /[0-9]/ ? e.to_i : e }
        val.length == 1 ? val.first : val
      end
    end
    url_parameters_hash[:rv] = parse_vehicle(url_parameters_hash[:rv])
    url_parameters_hash[:EX] = parse_exception_cells(url_parameters_hash[:EX])
    url_parameters_hash
  end

  def parse_vehicle(vehicles)
    vehicles.map { |v| v.split(',') }.map { |a| [a[0].split('%')[1], a[1..3].map { |e| e.to_i }] }.sort_by { |a| a[1] }.map do |a|
      [:name, :width, :length, :height].zip([a[0], *a[1]]).to_h
    end.reverse
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

  def make_deck_cells(params)
    cells = Array.new(params[:deck_length]) { Array.new(params[:deck_width], params[:stdmax]) }
    params[:EX].each_pair { |key, val| key[:width].each { |i| key[:length].each { |j| cells[i][j] = val } } }
    cells
  end

  def convert_column_name_to_int(name)
    name.downcase.split('').map { |c| c.ord % 'a'.ord }.map.with_index { |pos, i| pos*10**i}.reduce(:+)
  end

  def fit_all_vehicle_onto_deck(deck, params)
    cursor = { width: 0, length: 0 }
    top_map = Array.new(deck.first.length+1, 0)
    top_map[-1] = deck.length
    params[:rv].each do |vehicle|
      end_cursor = { width: cursor[:width]+vehicle[:width], length: cursor[:length]+vehicle[:length] }
      top_map_min = top_map.min
      top_map_index = top_map.index(top_map_min)
      while !check_fit_vehicle_onto_deck(deck, end_cursor, vehicle, cursor) && top_map_min != deck.length do
        if cursor[:length] == top_map_min && cursor[:width] == top_map_index
          top_map[top_map_index] = top_map[top_map_index-1] < top_map[top_map_index+1] ?
              top_map[top_map_index-1] : top_map[top_map_index+1]
          top_map_min = top_map.min
          top_map_index = top_map.index(top_map_min)
        end
        cursor[:length] = top_map_min
        cursor[:width] = top_map_index
        end_cursor = { width: cursor[:width]+vehicle[:width], length: cursor[:length]+vehicle[:length] }
      end
      if top_map.min != deck.length
        fit_vehicle_onto_deck(deck, vehicle[:name], end_cursor, cursor, top_map)
      end
    end
    deck
  end

  def check_fit_vehicle_onto_deck(deck, end_cursor, vehicle, cursor)
    if deck.length >= end_cursor[:length] && deck.first.length >= end_cursor[:width]
      (cursor[:length]..end_cursor[:length]-1).each do |i|
        (cursor[:width]..end_cursor[:width]-1).each { |j| return FALSE if deck[i][j].is_a?(Fixnum) && deck[i][j] < vehicle[:height] }
      end
    end
  end

  def fit_vehicle_onto_deck(deck, vehicle_name, end_cursor, cursor, top_map)
    (cursor[:length]..end_cursor[:length]-1).each do |i|
      (cursor[:width]..end_cursor[:width]-1).each { |j| deck[i][j] = vehicle_name }
    end
    (cursor[:width]..end_cursor[:width]-1).each { |i| top_map[i] = end_cursor[:length] }
    cursor[:width] = end_cursor[:width]
    # cursor[:length] += vehicle[:length]-1
  end

end

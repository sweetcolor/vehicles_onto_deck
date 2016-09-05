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
    vehicles.map { |v| v.split(',') }.map { |a| [a[0], a[1..3].map { |e| e.to_i }] }.sort_by { |a| a[1] }.to_h
  end

  def parse_exception_cells(cells)
    cells.map.with_index do |cell, i|
      if i.odd?
        cell.to_i
      else
        [
            Range.new(*cell.scan(/[A-Z]+/).map { |str| convert_column_name_to_int(str) }),
            Range.new(*cell.scan(/[0-9]+/).map { |num| num.to_i - 1 })
        ]
      end
    end.each_slice(2).to_h
  end

  def make_deck_cells(params)
    cells = Array.new(params[:deck_length]) { Array.new(params[:deck_width], params[:stdmax]) }
    params[:EX].each_pair { |key, val| key.first.each { |i| key[1].each { |j| cells[i][j] = val } } }
    cells
  end

  def convert_column_name_to_int(name)
    name.downcase.split('').map { |c| c.ord % 'a'.ord }.map.with_index { |pos, i| pos*10**i}.reduce(:+)
  end

  def fit_onto_deck
  end
end

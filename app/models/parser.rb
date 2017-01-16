class Parser
  def initialize(query)
    @query = query
    @parsed_query = Hash.new
  end

  def parse
    @parsed_query = parse_query
    @parsed_query[:sort_order] = parse_sort_order
    @parsed_query[:rv] = parse_real_vehicle
    @parsed_query[:SV] = parse_standard_vehicle
    @parsed_query[:EX] = @parsed_query.include?(:EX) ? parse_exception_cells : Hash.new
    @parsed_query[:LL] = parse_lane_line
    @parsed_query[:BD] = parse_b_double_vehicles
    @parsed_query[:SHC] = special_height_cell_colour
    @parsed_query
  end

  private

  def parse_query
    without_underscore_param = Set.new(%w{deck_width deck_length stdmax sort_order placement LL c})
    single_value_param = Set.new(%w{deck_width deck_length stdmax placement c W})
    int_array_param = Set.new(%w{LL BD})
    weight_param = Set.new(%w{WL})
    url_parameters_hash = Hash.new
    splitted_query = @query.split('~').map { |param| param.split('=') }
    splitted_query.map! { |e| without_underscore_param.include?(e.first) ? e : e.map { |sub_e| sub_e.split('_') }.flatten }
    splitted_query.each do |elem_query|
      key = elem_query.first
      last = elem_query[elem_query.length-1]
      url_parameters_hash[key.to_sym] = if single_value_param.include?(key)
                                          last =~ /[0-9]/ ? last.to_i : last
                                        elsif sv_param_key?(key) || int_array_param.include?(key)
                                          last.split(',').map do |e|
                                            e =~ /[0-9]/ ? e.to_i : e
                                          end
                                        elsif weight_param.include?(key)
                                          splitted_query << elem_query[2..-1]
                                          elem_query[1].to_i
                                        else
                                          elem_query.length > 2 ? elem_query[1..elem_query.length] : elem_query[1]
                                        end
    end
    url_parameters_hash
  end

  def sv_param_key?(param_key)
    param_key =~ /sv/
  end

  def parse_lane_line
    { column: @parsed_query[:LL][0], colour: @parsed_query[:LL][1..-1] }
  end

  def parse_b_double_vehicles
    [:length, :limit].zip(@parsed_query.include?(:BD) ? @parsed_query[:BD] : [@parsed_query[:deck_length]+1, 0]).to_h
  end

  def special_height_cell_colour
    if @parsed_query[:a].first == 'vis'
      shc = Hash.new
      @parsed_query[:a][1..-1].each_slice(2).to_h.each do |key, val|
        parse_val = val.split(',').map { |e| e.to_i }
        shc[parse_val[0]] = { name: key, colour: parse_val[1..-1] }
      end
      shc
    end
  end

  def parse_standard_vehicle
    create_vehicles_hash(@parsed_query.select { |k| sv_param_key?(k) }.each_value { |e| e.unshift(1) })
  end

  def parse_real_vehicle
    sort_vehicle create_vehicles_hash(@parsed_query[:rv].map { |v| v.split(',') }.map { |a| [a[0], a[1...a.length].map { |e| e.to_i }] })
  end

  def create_vehicles_hash(vehicles_array)
    vehicles_array.map { |a| Vehicle.new([:name, :stop, :width, :length, :height, :UN].zip([a[0], *a[1]]).to_h) }
  end

  def parse_sort_order
    values = { S: :stop, L: :length, W: :width, H: :height }
    @parsed_query[:sort_order].split(',').map do |e|
      order = e.scan(/[0-9]+/).first.to_i
      name = e.scan(/[A-Z]+/).first.to_s.to_sym
      [values[name], order.zero? ? 1 : -1]
    end
  end

  def sort_vehicle(vehicle)
    vehicle.sort_by { |v| @parsed_query[:sort_order].map { |s| s[1]*v[s[0]] } }
  end

  def parse_exception_cells
    @parsed_query[:EX].map.with_index do |cell, i|
      if i.odd?
        cell.to_i
      else
        [:length, :width].zip([
                                  Range.new(*cell.scan(/[0-9]+/).map { |num| num.to_i - 1 }),
                                  Range.new(*cell.scan(/[A-Z]+/).map { |str| excel_col_index(str) - 1 })
                              ]).to_h
      end
    end.each_slice(2).to_h
  end

  def excel_col_index( str )
    offset = 'A'.ord - 1
    str.chars.inject(0){ |x,c| x*26 + c.ord - offset }
  end
end

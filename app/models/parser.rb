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
    @parsed_query[:EX] = parse_exception_cells
    @parsed_query
  end

  private

  def parse_query
    url_parameters_hash = Hash.new
    splitted_query = @query.split('~').map { |param| param.split('=') }
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
    url_parameters_hash
  end

  def parse_standard_vehicle
    create_vehicles_hash(@parsed_query.select { |k| k =~ /sv/})
  end

  def parse_real_vehicle
    sort_vehicle create_vehicles_hash(@parsed_query[:rv].map { |v| v.split(',') }.map { |a| [a[0], a[1..3].map { |e| e.to_i }] })
  end

  def create_vehicles_hash(vehicles_array)
    vehicles_array.map { |a| Vehicle.new([:name, :width, :length, :height].zip([a[0], *a[1]]).to_h) }
  end

  def parse_sort_order
    values = %w(L W H)
    @parsed_query[:sort_order].insert(2, (values - @parsed_query[:sort_order][0..1]).first)
  end

  def sort_vehicle(vehicle)
    values = { L: :length, W: :width, H: :height }
    sort = @parsed_query[:sort_order][0..2].map { |order| values[order.to_s.to_sym] }
    vehicle_sorted = vehicle.sort_by { |v| [v[sort[0]], v[sort[1]], v[sort[2]]] }
    (@parsed_query[:sort_order][-1] == 1 ? vehicle_sorted.reverse : vehicle_sorted)
  end

  def parse_exception_cells
    @parsed_query[:EX].map.with_index do |cell, i|
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

  def convert_column_name_to_int(name)
    name.downcase.split('').map { |c| c.ord % 'a'.ord }.map.with_index { |pos, i| pos*10**i}.reduce(:+)
  end
end
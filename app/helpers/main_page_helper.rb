module MainPageHelper
  def check_if_drawn_vehicle(name, row, col)
    @vehicles_location[name].keys.each do |range|
      if range[:length].cover?(row) && range[:width].cover?(col)
        return range
      end
    end
    FALSE
  end

  def convert_column_name_to_int(name)
    name.downcase.split('').map { |c| c.ord % 'a'.ord }.map.with_index { |pos, i| pos*10**i}.reduce(:+)
  end
end

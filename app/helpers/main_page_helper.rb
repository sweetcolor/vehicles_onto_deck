module MainPageHelper
  def check_if_drawn_vehicle(name, row, col)
    @deck.vehicles_location[name].keys.each do |range|
      if range[:length].cover?(row) && range[:width].cover?(col)
        return range
      end
    end
    FALSE
  end
end

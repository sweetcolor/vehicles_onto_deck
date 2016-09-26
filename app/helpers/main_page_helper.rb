module MainPageHelper
  def check_if_drawn_vehicle(name, row, col)
    @deck.vehicles_location[name].keys.each do |range|
      if range[:length].cover?(row) && range[:width].cover?(col)
        return range
      end
    end
    FALSE
  end

  def index_to_excel_col(idx)
    letters = ('A'..'Z').to_a
    s, q = '', idx
    (q, r = (q - 1).divmod(26)) && s.prepend(letters[r]) until q.zero?
    s
  end
end

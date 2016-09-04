module MainPageHelper
  def get_url_parameters
    %w[deck_width deck_length stdmax EX sv rv sort_order placement a LL c].zip([nil]).to_h
  end
end

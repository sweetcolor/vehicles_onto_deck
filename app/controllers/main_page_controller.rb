class MainPageController < ApplicationController
  def index
  end

  def query
    @url_parameters = parse_query params[:query]
    @cells = make_deck_cells(@url_parameters)
    @deck = fit_all_vehicle_onto_deck(@cells.deep_dup, @url_parameters)
  end
end

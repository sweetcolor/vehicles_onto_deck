class MainPageController < ApplicationController
  def index
  end

  def query
    @url_parameters = parse_query params[:query]
    @deck = make_deck_cells(@url_parameters)
  end
end

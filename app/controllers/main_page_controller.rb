class MainPageController < ApplicationController
  before_action :set_url_parameters, only: [:query]

  def index
  end

  def query
    @query = params[:query]
    splitted_query = @query.split('~').map { |param| param.split('=') }
    splitted_query.map! { |e| e.length != 2 ? e.map { |sub_e| sub_e.split('_') }.flatten : e }
    splitted_query.each { |e| @url_parameters[e.first] = e[1..e.length] }
    @url_parameters
  end

  private
  def set_url_parameters
    @url_parameters = get_url_parameters
  end
end

class MainPageController < ApplicationController
  def index
  end

  def query
    @parsed_query = Parser.new(params[:query]).parse
    reinitialize
    if b_placement?
      ul_placement = 'UL'
      fit_vehicles(ul_placement)
      ul_deck = @deck.deep_dup
      ul_inserted_vehicles = @inserted_vehicles.deep_dup
      ul_answer = @answer

      reinitialize
      lu_placement = 'LU'
      fit_vehicles(lu_placement)
      lu_deck = @deck.deep_dup
      lu_inserted_vehicles = @inserted_vehicles.deep_dup
      lu_answer = @answer
      if compare_results_of_placements(ul_answer, ul_inserted_vehicles, lu_answer, lu_inserted_vehicles) == ul_placement
        @deck = ul_deck
        @answer = ul_answer
        @inserted_vehicles = ul_inserted_vehicles
      else
        @deck = lu_deck
        @answer = lu_answer
        @inserted_vehicles = lu_inserted_vehicles
      end
    else
      fit_vehicles(@parsed_query[:placement])
    end
    respond_to do |format|
      format.html
      format.json { render json: @deck }
    end
  end

  private

  def reinitialize
    @inserted_vehicles = Hash.new
    @deck = Deck.new(@parsed_query[:deck_length], @parsed_query[:deck_width], @parsed_query[:LL])
    @deck.special_height_cell_colour = @parsed_query[:SHC]
    @deck.vehicles = @parsed_query[:rv].map { |v| v[:name] }.to_set
    @deck.make_deck_cells(@parsed_query[:stdmax], @parsed_query[:EX], vis_answer?)
  end

  def compare_results_of_placements(ul_answer, ul_inserted_vehicles, lu_answer, lu_inserted_vehicles)
    best_placement = 'UL'
    if ul_answer[:fitted_veh_count] > lu_answer[:fitted_veh_count]
      best_placement = 'UL'
    elsif ul_answer[:fitted_veh_count] < lu_answer[:fitted_veh_count]
      best_placement = 'LU'
    else
      @parsed_query[:SV].each do |std_veh|
        if ul_inserted_vehicles[std_veh.name] > lu_inserted_vehicles[std_veh.name]
          best_placement = 'UL'
          break
        elsif ul_inserted_vehicles[std_veh.name] < lu_inserted_vehicles[std_veh.name]
          best_placement = 'LU'
          break
        end
      end
    end
    best_placement
  end

  def fit_vehicles(placement)
    @parsed_query[:placement] = placement
    area = Area.new(CellCursor.new(0, 0), CellCursor.new(@deck.width-1, @deck.length-1))
    @areas = Areas.new([area], @parsed_query[:placement])
    fit_vehicles_onto_deck(:rv, lambda { |*argv| insert_real_vehicle(*argv) })
    insert_standard_vehicle
    @answer = get_answer
    @deck.prepare_to_drawing
  end

  def get_answer
    count_fitted = count_real_vehicle_fitted
    answer = count_fitted.zero? ? FALSE : TRUE
    all = @parsed_query[:rv].length == count_fitted ? TRUE : FALSE
    { answer: answer, fitted_veh_count: count_fitted, all: all }
  end

  def fit_vehicles_onto_deck(vehicle_type, vehicle_insert_func)
    prepare_vehicle(vehicle_type)
    @vehicles.each do |veh|
      areas = { new_areas: Hash.new, old_areas: Hash.new, not_fitted_areas: Set.new  }
      areas = vehicle_insert_func.call(areas, veh)
      @areas.reset(areas[:new_areas], areas[:old_areas])
    end
  end

  def prepare_vehicle(vehicle_type)
    @inserted_vehicles = @parsed_query[vehicle_type].reduce(@inserted_vehicles) { |h, v| h[v[:name]] = 0; h }
    @vehicles = remove_too_high_vehicle(@parsed_query[vehicle_type])
  end

  def insert_real_vehicle(areas, veh)
    while !@areas.empty? && @inserted_vehicles[veh.name].zero?
      areas = try_insert_vehicle(areas, veh)
    end
    areas
  end

  def insert_standard_vehicle
    prepare_vehicle(:SV)
    @vehicles.each do |veh|
      areas = { new_areas: Hash.new, old_areas: Hash.new, not_fitted_areas: Set.new }
      @areas.reset(areas[:new_areas], areas[:old_areas])
        while !@areas.empty? && @areas.any_fitted?(areas[:not_fitted_areas])
          areas = try_insert_vehicle(areas, veh)
          @areas.reset(areas[:new_areas], areas[:old_areas]) if areas[:not_fitted_areas].empty?
        end
    end
  end

  def try_insert_vehicle(areas, veh)
    area = @areas.get_next
    veh_begin_cursor, veh_end_cursor = area.begin_cursor, area.begin_cursor + CellCursor.new(veh.width-1, veh.length-1)
    veh_area = Area.new(veh_begin_cursor, veh_end_cursor)
    result_of_checking = @deck.check_fit_vehicle_onto_deck(veh, veh_area, area)
    if result_of_checking[:fitted]
      @deck.put_vehicle_onto_deck(veh, veh_area)
      areas.merge! area.put_vehicle(veh_area, @areas.areas_hash)
      @inserted_vehicles[veh.name] += 1
      areas[:not_fitted_areas].clear
    elsif result_of_checking[:too_high]
      small_height_area = Area.new(veh_begin_cursor, result_of_checking[:small_height_end_cursor])
      copy_areas = @areas.deep_dup
      next_areas_to_small_height = areas.deep_dup
      next_areas_to_small_height.merge!(area.deep_dup.put_vehicle(small_height_area, copy_areas.areas_hash))
      next_areas_to_small_height[:old_areas][area.name] = area
      begin
        # TODO if veh not fit
        copy_areas.reset(next_areas_to_small_height[:new_areas], next_areas_to_small_height[:old_areas])
        area = copy_areas.get_next
        veh_begin_cursor, veh_end_cursor = area.begin_cursor, area.begin_cursor + CellCursor.new(veh.width-1, veh.length-1)
        veh_area = Area.new(veh_begin_cursor, veh_end_cursor)
        result_of_checking = @deck.check_fit_vehicle_onto_deck(veh, veh_area, area)
        if result_of_checking[:fitted]
          area = @areas.find_area(area.begin_cursor)
          @deck.put_vehicle_onto_deck(veh, veh_area)
          areas.merge! area.put_vehicle(veh_area, @areas.areas_hash)
          @inserted_vehicles[veh.name] += 1
          areas[:not_fitted_areas].clear
          break
        end
      end until copy_areas.empty?
    else
      areas[:not_fitted_areas].add(area.name)
    end
    areas
  end

  def count_real_vehicle_fitted
    @inserted_vehicles.slice(*@parsed_query[:rv].map { |v| v[:name] }).values.count { |s| !s.zero? }
  end

  def remove_too_high_vehicle(vehicles)
    vehicles.map { |veh| veh if veh[:height] <= @deck.max_height }.compact
  end

  def vis_answer?
    @parsed_query[:a].first == 'vis'
  end

  def b_placement?
    @parsed_query[:placement] == 'B'
  end
end

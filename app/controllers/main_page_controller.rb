class MainPageController < ApplicationController
  def index
  end

  def query
    @deck = nil
    @parsed_query = Parser.new(params[:query]).parse
    @types_of_dangerous = get_types_of_dangerous
    if any_overwidth_vehicles
      @answer = { overwidth: true }
    elsif @types_of_dangerous.length  > 2
      @answer = { too_many_types_of_dangerous: true }
    else
      draw_deck
    end
    respond_to do |format|
      format.html
      format.json { render json: @deck }
    end
  end

  private

  def any_overwidth_vehicles
    @parsed_query[:rv].any? { |veh| veh.width < 0 }
  end

  def get_types_of_dangerous
    types_of_dangerous = Set.new
    @parsed_query[:rv].each do |vehicle|
      types_of_dangerous.add(vehicle.un) unless vehicle.un.zero?
    end
    types_of_dangerous
  end

  def draw_deck
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
  end

  def reinitialize
    @inserted_vehicles = Hash.new
    @b_double_count = 0
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
        if ul_inserted_vehicles[std_veh.name][:count] > lu_inserted_vehicles[std_veh.name][:count]
          best_placement = 'UL'
          break
        elsif ul_inserted_vehicles[std_veh.name][:count] < lu_inserted_vehicles[std_veh.name][:count]
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
    @areas_original = @areas
    fit_vehicles_onto_deck(:rv, lambda { |*argv| insert_real_vehicle(*argv) })
    fit_vehicles_onto_deck(:SV, lambda { |*argv| insert_standard_vehicle(*argv) })
    @answer = get_answer
  end

  def get_answer
    count_fitted = count_real_vehicle_fitted
    answer = count_fitted.zero? ? FALSE : TRUE
    all = @parsed_query[:rv].length == count_fitted ? TRUE : FALSE
    weight_limit_breached = weight_limit_exists? ? @parsed_query[:W] > @parsed_query[:WL] : false
    { overwidth: false, answer: answer, fitted_veh_count: count_fitted, all: all, wl_breached: weight_limit_breached,
      too_many_types_of_dangerous: false }
  end

  def prepare_vehicle(vehicle_type)
    @inserted_vehicles = @parsed_query[vehicle_type].reduce(@inserted_vehicles) do |h, v|
      h[v[:name]] = { count: 0, b_double_rule: false }
      h
    end
    @vehicles = remove_too_high_vehicle(@parsed_query[vehicle_type])
    @vehicles.each do |vehicle|
      @parsed_query[:EX].each_pair do |exc_range, exc_height|
        if vehicle.height > exc_height
          exc_area = Area.new(
              CellCursor.new(exc_range[:width].begin, exc_range[:length].begin),
              CellCursor.new(exc_range[:width].end, exc_range[:length].end)
          )
          vehicle.exception_areas << exc_area
        end
      end
    end
  end

  def fit_vehicles_onto_deck(vehicle_type, vehicle_insert_func)
    prepare_vehicle(vehicle_type)
    if @types_of_dangerous.length == 2 && vehicle_type == :rv
      dangerous_vehicles = @vehicles.select { |veh| @types_of_dangerous.include?(veh.un) }
      right_corner = @types_of_dangerous.to_a[1]
      dangerous_vehicles.map { |dang_veh| dang_veh.right_corner = true if dang_veh.un == right_corner }
      @vehicles = dangerous_vehicles + (@vehicles - dangerous_vehicles)
    end
    @vehicles.each do |veh|
      set_areas(veh)
      vehicle_insert_func.call(veh)
    end
  end

  def set_areas(vehicle)
    if vehicle.exception_areas.empty?
      @areas = Areas.new(@areas_original.areas_array, @parsed_query[:placement])
    else
      @areas = Areas.new(@areas_original.areas_array, @parsed_query[:placement])
      vehicle.exception_areas.each do |exc_area|
        until @areas.empty?
          area = @areas.get_next
          areas = area.try_put_vehicle_in_cross_area(exc_area, @areas.areas_hash)
          if !areas[:new_areas].empty? || !areas[:old_areas].empty?
            @areas.reset(areas[:new_areas], areas[:old_areas])
          end
        end
        @areas.reset(Hash.new, Hash.new)
      end
    end
    @areas.reset(Hash.new, Hash.new)
  end

  def insert_real_vehicle(veh)
    areas = { new_areas: Hash.new, old_areas: Hash.new, not_fitted_areas: Set.new }
    while !@areas.empty? && @inserted_vehicles[veh.name][:count].zero?
      areas = try_insert_vehicle(areas, veh)
    end
    @areas_original.reset(areas[:new_areas], areas[:old_areas])
  end

  def insert_standard_vehicle(veh)
    areas = { new_areas: Hash.new, old_areas: Hash.new, not_fitted_areas: Set.new }
    @areas.reset(areas[:new_areas], areas[:old_areas])
    while !@areas.empty? && @areas.any_fitted?(areas[:not_fitted_areas])
      areas = try_insert_vehicle(areas, veh)
      if areas[:not_fitted_areas].empty?
        @areas_original.reset(areas[:new_areas], areas[:old_areas])
        set_areas(veh)
      end
    end
  end

  def try_insert_vehicle(areas, veh)
    b_double = veh.length > @parsed_query[:BD][:length]
    b_double_rule_true = b_double ? @b_double_count >= @parsed_query[:BD][:limit] : false
    area = @areas.get_next
    if veh.right_corner
      veh_begin_cursor, veh_end_cursor = CellCursor.new(area.end_cursor.width-veh.width+1, area.begin_cursor.length),
          CellCursor.new(area.end_cursor.width, area.begin_cursor.length+veh.length-1)
    else
      veh_begin_cursor, veh_end_cursor = area.begin_cursor, area.begin_cursor + CellCursor.new(veh.width-1, veh.length-1)
    end
    veh_area = Area.new(veh_begin_cursor, veh_end_cursor)
    result_of_checking = @deck.check_fit_vehicle_onto_deck(veh, area)
    if result_of_checking[:fitted] && !b_double_rule_true
      @deck.put_vehicle_onto_deck(veh, veh_area)
      unless veh.exception_areas.empty?
        @areas_original.reset(Hash.new, Hash.new)
        area = @areas_original.find_area(area.begin_cursor)
      end
      areas.merge! area.put_vehicle(veh_area, @areas_original.areas_hash)
      @inserted_vehicles[veh.name][:count] += 1
      @b_double_count += 1 if b_double
      areas[:not_fitted_areas].clear
    else
      @inserted_vehicles[veh.name][:b_double_rule] = true if b_double_rule_true
      areas[:not_fitted_areas].add(area.name)
    end
    areas
  end

  def count_real_vehicle_fitted
    @inserted_vehicles.slice(*@parsed_query[:rv].map { |v| v[:name] }).values.count { |s| !s[:count].zero? }
  end

  def remove_too_high_vehicle(vehicles)
    vehicles.map { |veh| veh if veh[:height] <= @deck.max_height }.compact
  end

  def vis_answer?
    @parsed_query[:a].first == 'vis'
  end

  def weight_limit_exists?
    @parsed_query.include?(:WL) && @parsed_query.include?(:W)
  end

  def b_placement?
    @parsed_query[:placement] == 'B'
  end
end

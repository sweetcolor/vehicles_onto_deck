(($) ->
  ajax = $.getJSON(document.URL)
  get_css_sum_int_value = (elem, style) ->
    elem.css(style).split(' ').map((e) -> parseInt(e, 10)).reduce ((a, b) -> a + b), 0

  get_max = (array) ->
    max = array[0]
    array[1..-1].forEach (e)->
      if e > max
        max = e
    max

  find_nearest_cursor = (height, width, cursors) ->
    nearest = 100000000
    nearest_cursor = null
    Object.keys(cursors).forEach((name)->
      splitted = name.split("_")
      distance = Math.abs(height - parseInt(splitted[1])) + Math.abs(width - parseInt(splitted[0]))
      if (nearest_cursor > distance)
        nearest = distance
        nearest_cursor = cursors[name]
    )
    nearest_cursor

  ajax.done((deck) ->
    wrapper = $(".vehicles-visual-table")
    wrapper.css("background-color", "rgb("+deck.std_colour.join(',')+")")
    width_full = wrapper.width()
    width = width_full / deck.width
    height_full = wrapper.height()
    height = height_full / deck.length
    cell = { width: width, height: height }
    console.log cell
    next_cursors = { '0_0': { left: 0, top: 0 } }
    deck.vehicles_position.forEach (e) ->
      begin_width = e.area.begin_cursor.width
      begin_height = e.area.begin_cursor.length

      end_width = e.area.end_cursor.width
      end_height = e.area.end_cursor.length
      a = $('#a'+begin_height+'_'+begin_width)
      a.addClass('vehicles-visual-cell')
      curr_cell_width = cell.width * (end_width - begin_width + 1)
      curr_cell_height = cell.height * (end_height - begin_height + 1)
      curcor_name = begin_width + '_' + begin_height
      if Object.keys(next_cursors).includes(curcor_name)
        curr_cursor = next_cursors[curcor_name]
      else
        curr_cursor = { left: begin_width*cell.width+3, top: begin_height*cell.height+3 }
      next_cursors[begin_width + '_' + (end_height+1)] = { left: curr_cursor.left, top: curr_cursor.top + curr_cell_height+1 }
      next_cursors[(end_width+1) + '_' + begin_height] = { left: curr_cursor.left + curr_cell_width+1, top: curr_cursor.top }
      a.width(curr_cell_width)
      a.height(curr_cell_height)
      a.css({ left: curr_cursor.left, top: curr_cursor.top, "background-color": "rgb("+deck.std_colour.join(',')+")" })
      delete next_cursors[curcor_name]

    lane_width = width_full / (deck.lane_line.column+1)
    [1..deck.lane_line.column].forEach (i) ->
      line = $("#l"+(i-1))
      line.height(height_full)
      line.width("1px")
      colour = deck.lane_line.colour.join(',')
      line.css({ left: i*lane_width+(i-1), top: 0, 'border-color': "rgb("+colour+")" })

    Object.keys(deck.exception_colour).forEach (height) ->
      c = $('#c'+height)
      exc = deck.exception_colour[height]
      width = exc.width.split("..").map((e)-> parseInt(e,10))
      beg_width = width[0]
      end_width = width[1]
      length = exc.length.split("..").map((e)-> parseInt(e,10))
      beg_length = length[0]
      end_length = length[1]
      left = beg_width * cell.width
      top = beg_length * cell.height
      colour = exc.colour
      c.css({
        left: left, top: top, "background-color": "rgb("+colour.join(',')+")", width: (end_width-beg_width+1)*cell.width, height: (end_length-beg_length+1)*cell.height
      })
  )
)(jQuery)

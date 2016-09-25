(($) ->
  ajax = $.getJSON(document.URL)
  get_css_sum_int_value = (elem, style) ->
    elem.css(style).split(' ').map((e) -> parseInt(e, 10)).reduce ((a, b) -> a + b), 0

  ajax.done((deck) ->
    wrapper = $(".vehicles-visual-table")
    wrapper.css("background-color", "rgb("+deck.std_colour.join(',')+")")
    width_full = wrapper.width()
    width = width_full / deck.width
    height_full = wrapper.height()
    height = height_full / deck.length
    cell = { width: width, height: height }
    next_cursors = { '0_0': { left: 0, top: 0 } }
    deck.vehicles_position.forEach (pos) ->
      begin_width = pos.area.begin_cursor.width
      begin_height = pos.area.begin_cursor.length

      end_width = pos.area.end_cursor.width
      end_height = pos.area.end_cursor.length
      a = $('#a'+begin_height+'_'+begin_width)
      curr_cell_width = cell.width * (end_width - begin_width + 1)
      curr_cell_height = cell.height * (end_height - begin_height + 1)
      a.width(curr_cell_width)
      a.height(curr_cell_height)
      if pos.aligned_to_top
        a.addClass('aligned_to_top')
      else
        a.height(a.height()-1)
      if pos.aligned_to_left
        a.addClass('aligned_to_left')
      else
        a.width(a.width()-1)
      left = cell.width * begin_width
      top = cell.height * begin_height
      background_color = "rgb(" + deck.std_colour.join(',') + ")"
      a.css({ left: left, top: top, "background-color": background_color })

    lane_width = width_full / (deck.lane_line.column+1)
    [1..deck.lane_line.column].forEach (i) ->
      line = $("#l"+(i-1))
      line.height(height_full)
      line.width("1px")
      colour = deck.lane_line.colour.join(',')
      line.css({ left: i*lane_width-1, top: 0, 'border-color': "rgb("+colour+")" })

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

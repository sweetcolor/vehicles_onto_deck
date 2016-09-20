# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

(($) ->
  ajax = $.getJSON(document.URL)
  get_css_sum_int_value = (elem, style) ->
    elem.css(style).split(' ').map((e) -> parseInt(e, 10)).reduce ((a, b) -> a + b), 0
  ajax.done((deck) ->
    vehicles_visual_table_property = $('.vehicles-visual-table')
    table_property_width = parseInt(vehicles_visual_table_property.css('width'))
    table_property_margin = get_css_sum_int_value(vehicles_visual_table_property, 'margin')
#    wrapper = $(".vehicles-visual-table")
#    width = wrapper.width()
    width_full = window.innerWidth * 0.9
    width = width_full - table_property_width - table_property_margin*2
    height_full = window.innerHeight * 0.95
    vehicles_visual_table_property.height(height_full+2)
#    height = wrapper.height()
    height = height_full / deck.length
    cell = { width: (width) / deck.width, height: height }
    console.log cell
    row = 0
    col = 0
    deck.vehicles_position.forEach (e)->
      begin_col = e.area.begin_cursor.width
      begin_row = e.area.begin_cursor.length

      end_col = e.area.end_cursor.width
      end_row = e.area.end_cursor.length
      a = $('#a'+begin_row+'_'+begin_col)
      a.addClass('vehicles-visual-cell')
      pad = get_css_sum_int_value(a, 'padding')
      border = parseInt(a.css("border").split(' ')[0])
      left = (border) * begin_col + 1
#      top = (border) * begin_row
#      top = cell.height*begin_row
      top = 2
#      left = 0
      if begin_col != 0
        begin_col -= 1
      if begin_row != 0
        begin_row += 1
      left += begin_col * cell.width + 1
      top += begin_row * cell.height

      a.width(cell.width * (end_col - begin_col))
      a.height(cell.height * (end_row - begin_row))
      a.css({ left: left, top: top })
    lane_width = width / (deck.lane_line.column+1)
    [1..deck.lane_line.column].forEach (i) ->
      line = $("#l"+(i-1))
      line.height(height_full)
      line.width("1px")
      colour = deck.lane_line.colour.join(',')
      line.css({ left: i*lane_width, top: 0, 'border-color': "rgb("+colour+")" })
    [0..deck.length-1].forEach (i) ->
      [0..deck.width-1].forEach (j) ->
        c = $('#c'+i+'_'+j)
        left = j * cell.width
        top = i * cell.height
        colour = deck.cells[i][j].cell_hash.colour
        c.css({ left: left, top: top, "background-color": "rgb("+colour.join(',')+")", width: cell.width, height: cell.height })
  )
)(jQuery)

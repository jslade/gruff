require File.dirname(__FILE__) + '/base'
require File.dirname(__FILE__) + '/bar_conversion'
require File.dirname(__FILE__) + '/ldata_mixin'

class Gruff::Bar < Gruff::Base
  include LdataMixin

  def draw
    # Labels will be centered over the left of the bar if
    # there are more labels than columns. This is basically the same 
    # as where it would be for a line graph.
    @center_labels_over_point = (@labels.keys.length > @column_count ? true : false)
    
    super
    draw_bars if @has_data
    draw_ldata if @has_ldata
  end

protected

  def draw_bars
    # Setup spacing.
    #
    # Columns sit side-by-side.
    spacing_factor = 0.9 # space between the bars
    @bar_width = @graph_width / (@column_count * @data.length).to_f
    padding = (@bar_width * (1 - spacing_factor)) / 2

    @d = @d.stroke_opacity 0.0

    # Setup the BarConversion Object
    conversion = Gruff::BarConversion.new()
    conversion.graph_height = @graph_height
    conversion.graph_top = @graph_top

    # Set up the right mode [1,2,3] see BarConversion for further explanation
    if @minimum_value >= 0 then
      # all bars go from zero to positiv
      conversion.mode = 1
    else
      # all bars go from 0 to negativ
      if @maximum_value <= 0 then
        conversion.mode = 2
      else
        # bars either go from zero to negativ or to positiv
        conversion.mode = 3
        conversion.spread = @spread
        conversion.minimum_value = @minimum_value
        conversion.zero = -@minimum_value/@spread
      end
    end

    # iterate over all normalised data
    @norm_data.each_with_index do |data_row, row_index|

      data_row[DATA_VALUES_INDEX].each_with_index do |data_point, point_index|
        # Use incremented x and scaled y
        # x
        left_x = @graph_left + (@bar_width * (row_index + point_index + ((@data.length - 1) * point_index))) + padding
        right_x = left_x + @bar_width * spacing_factor
        # y
        conv = []
        conversion.getLeftYRightYscaled( data_point, conv )

        # create new bar
        @d = @d.fill data_row[DATA_COLOR_INDEX]
        @d = @d.rectangle(left_x, conv[0], right_x, conv[1])

        # Calculate center based on bar_width and current row
        label_center = @graph_left + 
                      (@data.length * @bar_width * point_index) + 
                      (@data.length * @bar_width / 2.0)
        # Subtract half a bar width to center left if requested
        draw_label(label_center - (@center_labels_over_point ? @bar_width / 2.0 : 0.0), point_index)

	if @has_ldata
	  @ldata_offset_and_increment[row_index] ||=
	    [ label_center, @bar_width * @norm_data.size ]
	end
      end
      
    end

    # Draw the last label if requested
    draw_label(@graph_right, @column_count) if @center_labels_over_point

    @d.draw(@base_image)
  end

  
  def calc_ldata_on_bar row_index, point_index, label_center, bar_width
    # Save the x mid point of the first bar and the x distance between 2
    # bars of the same data set to be used to position ldata points.
    line_info = @ldata_offset_and_increment[row_index] ||= Array.new
    if point_index == 0
      line_info[0] = label_center
    else
      if line_info[1].nil?
	line_info[1] = label_center - line_info[0]
      end
    end
  end

  
end

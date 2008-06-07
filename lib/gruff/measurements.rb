require 'ostruct'

module Gruff

  class Base

    protected

    # Calculates size of drawable area, general font dimensions, etc.
    def setup_graph_measurements
      setup_caps_heights
      setup_margins
      setup_graph_area
    end


    def setup_caps_heights
      @marker_caps_height = @hide_line_markers ? 0 :
                             calculate_caps_height(@marker_font_size)
      @title_caps_height = @hide_title ? 0 :
                            calculate_caps_height(@title_font_size)
      @legend_caps_height = @hide_legend ? 0 :
                             calculate_caps_height(@legend_font_size)
    end


    def setup_margins
      @hide_line_markers ? 
        setup_margins_without_markers :
	setup_margins_with_markers
      setup_x_axis_label
    end

    def setup_margins_without_markers
      @graph_left = @left_margin
      @graph_right_margin = @right_margin
      @graph_bottom_margin = @bottom_margin
    end
    
    def setup_margins_with_markers
      setup_left_margin_with_markers
      setup_right_margin_with_markers
      setup_bottom_margin_with_markers
    end

    def setup_left_margin_with_markers
      @longest_left_label_width = 0
      if @has_left_labels
	@longest_left_label_width = 
	  calculate_width(@marker_font_size, longest_string(labels)) * 1.25
      else
	@longest_left_label_width = 
	  calculate_width(@marker_font_size, label(@maximum_value.to_f))
      end

      # Shift graph if left line numbers are hidden
      @line_number_width = @hide_line_numbers && !@has_left_labels ? 
        0.0 : (@longest_left_label_width + LABEL_MARGIN * 2)

      @graph_left = @left_margin + 
	@line_number_width + 
	(@y_axis_label.nil? ? 0.0 : @marker_caps_height + LABEL_MARGIN * 2)
    end

    def setup_right_margin_with_markers
      # Make space for half the width of the rightmost column label.
      # Might be greater than the number of columns if between-style
      # bar markers are used.
      last_label = @labels.keys.sort.last.to_i
      extra_room_for_long_label =
	(last_label >= (@column_count-1) && @center_labels_over_point) ?
        calculate_width(@marker_font_size, @labels[last_label])/2.0 : 0
      @graph_right_margin = @right_margin + extra_room_for_long_label
    end

    def setup_bottom_margin_with_markers
      # Height needed for x-axis labels:
      @labels_height = @marker_caps_height

      @label_rotation = 0 if @label_rotation < 0
      @label_rotation = 90 if @label_rotation > 90

      if @label_rotation != 0
	# Get length off longest label,
	# use that to calculate needed height adjustment
	# to bottom margin
	maxlabel = @labels.inject('') { |val,m|
	  (val.to_s.length > m.to_s.length) ? val : m
	}
	rot_margin = calculate_width(@marker_font_size, maxlabel) *
	  Math.sin(Math::PI * @label_rotation / 180)
	@labels_height += rot_margin.abs
      end

      @graph_bottom_margin =
	@bottom_margin + @labels_height + LABEL_MARGIN
    end

    def setup_x_axis_label
      unless @x_axis_label.nil?
	@x_axis_label_height = @x_axis_label.nil? ? 0.0 :
	  @marker_caps_height + LABEL_MARGIN
	@x_axis_label_margin = @bottom_margin + @x_axis_label_height
	@graph_bottom_margin += @x_axis_label_height
      end
    end

    def setup_graph_area
      @graph_right = @raw_columns - @graph_right_margin
      @graph_width = @graph_right - @graph_left

      # When @hide title, leave a TITLE_MARGIN space for aesthetics.
      # Same with @hide_legend
      @graph_top = @top_margin + 
	(@hide_title ? TITLE_MARGIN : @title_caps_height + TITLE_MARGIN * 2) +
	(@hide_legend ? LEGEND_MARGIN : @legend_caps_height + LEGEND_MARGIN * 2)
      @graph_bottom = @raw_rows - @graph_bottom_margin
      @graph_height = @graph_bottom - @graph_top
    end



    # Returns the height of the capital letter 'X' for the current font and
    # size.
    #
    # Not scaled since it deals with dimensions that the regular scaling will
    # handle.
    def calculate_caps_height(font_size)
      @d.pointsize = font_size
      @d.get_type_metrics(@base_image, 'X').height
    end

    # Returns the width of a string at this pointsize.
    #
    # Not scaled since it deals with dimensions that the regular 
    # scaling will handle.
    def calculate_width(font_size, text)
      @d.pointsize = font_size
      @d.get_type_metrics(@base_image, text.to_s).width
    end


    # Returns the longest string from a list of strings
    def longest_string(list)
      list.values.inject('') { |value, memo|
	(value.to_s.length > memo.to_s.length) ? value : memo
      }
    end

  end # Gruff::Base

end # Gruff

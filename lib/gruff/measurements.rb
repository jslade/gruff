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
    end

    def setup_margins_without_markers
      @graph_left = @left_margin
      @graph_right_margin = @right_margin
      @graph_bottom_margin = @bottom_margin
    end
    
    def setup_margins_with_markers
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
      
      # Make space for half the width of the rightmost column label.
      # Might be greater than the number of columns if between-style
      # bar markers are used.
      last_label = @labels.keys.sort.last.to_i
      extra_room_for_long_label =
	(last_label >= (@column_count-1) && @center_labels_over_point) ?
        calculate_width(@marker_font_size, @labels[last_label])/2.0 : 0
      @graph_right_margin = @right_margin + extra_room_for_long_label
                                
      @graph_bottom_margin =
	@bottom_margin + @marker_caps_height + LABEL_MARGIN
    end


    def setup_graph_area
      @graph_right = @raw_columns - @graph_right_margin
      @graph_width = @raw_columns - @graph_left - @graph_right_margin

      # When @hide title, leave a TITLE_MARGIN space for aesthetics.
      # Same with @hide_legend
      @graph_top = @top_margin + 
	(@hide_title ? TITLE_MARGIN : @title_caps_height + TITLE_MARGIN * 2) +
	(@hide_legend ? LEGEND_MARGIN : @legend_caps_height + LEGEND_MARGIN * 2)

      x_axis_label_height = @x_axis_label.nil? ? 0.0 :
                              @marker_caps_height + LABEL_MARGIN
      @graph_bottom = @raw_rows - @graph_bottom_margin - x_axis_label_height
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

  # Measurements class keeps track of all measurements for different
  # regions of the graph.  These measurements are available after
  # the graph is renderered -- use for testing, use for creating
  # a region map, etc
  class Measurements
    attr_reader :gruff
    attr_accessor :raw_rows, :raw_columns, :scale
    attr_accessor :left_margin, :right_margin, :top_margin, :bottom_margin
    attr_accessor :title_caps_height, :legend_caps_height,
      :marker_caps_height
    attr_accessor :longest_left_label_width, :line_number_width
    attr_accessor :graph_left, :graph_right, :graph_top, :graph_bottom
    attr_accessor :graph_left_margin, :graph_right_margin,
      :graph_top_margin, :graph_bottom_margin
    attr_accessor :graph_width, :graph_height
    attr_accessor :increment_scaled
    
    def initialize(gruff,rows,cols)
      @gruff = gruff
    end
    
  end # Gruff::Measurements
  

end # Gruff

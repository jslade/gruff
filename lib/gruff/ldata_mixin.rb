
module Gruff::Base::LdataMixin
  # add support for trend / target lines on bars and stacked bars
  
  # Same as data, but you can defined groups of lines.
  # The lines points will be x centered on the bar corresponding to
  # the group.
  def ldata(name, data_points=[], attrs={})
    attrs[:color] = increment_color if(attrs[:color].nil? or 
                                       attrs[:color] == 'auto')
    attrs[:group] = 0 if attrs[:group].nil?
    attrs[:line_width] = 5.0 if attrs[:line_width].nil?
    attrs[:dot_width] = 0.01 if attrs[:dot_width].nil?
    
    ldata_points = Array(data_points)
    
    @ldata << [name, ldata_points, attrs[:color], attrs]
    
    # Pre-normalize
    ldata_points.each_with_index do |data_point, index|
      next if data_point.nil?
      
      # Setup max/min so spread starts at the low end of the data points
      if @maximum_value.nil? && @minimum_value.nil?
        @maximum_value = @minimum_value = data_point
      end
      
      @maximum_value = larger_than_max?(data_point) ? data_point : @maximum_value
      @has_ldata = true if @maximum_value > 0
      @minimum_value = less_than_min?(data_point) ? data_point : @minimum_value
      @has_ldata = true if @minimum_value < 0
      
      # Make sure we draw the graph if we have line data, even if we
      # don't have data, or all the data is 0
      @has_data = true if @has_ldata
    end
    
  end
  
  
  protected 
  
  def initialize_ldata
    # Same as data but for line data
    @has_ldata = false
    @ldata = []
    @norm_ldata = []
    @ldata_offset_and_increment = []
  end


  # This is added to deal with having more ldata than data
  def pre_normalize_ldata
    # See what the longest line data serie is
    max_ldata_num = 0
    @ldata.each { |row|
      # See how many data points we have in here
      row_size = row[Gruff::Base::DATA_VALUES_INDEX].size
      max_ldata_num = row_size if max_ldata_num < row_size
    }

    # And make sure we have that many in at least one bar data serie
    @data.each { |row|
      vals = row[Gruff::Base::DATA_VALUES_INDEX]
      next if vals.size >= max_ldata_num
      (max_ldata_num - vals.size).times { vals.push(0) }
      @column_count = max_ldata_num if max_ldata_num > @column_count
    }
  end


  # Draw the lines, done after the base bars are done
  def draw_ldata
    @norm_ldata.each_with_index do |ldata_row, row_index|
      prev_x = prev_y = nil
      values = ldata_row[Gruff::Base::DATA_VALUES_INDEX]
      attrs = ldata_row[Gruff::Base::DATA_ATTRS_INDEX]
      group = attrs[:group]

      if @ldata_offset_and_increment[group].nil?
	puts "Invalid group #{group} given on line data. Resetting to group 0"
	group = 0
      end
      offset, increment = @ldata_offset_and_increment[group]
      
      values.each_with_index do |data_point, point_index|
        next unless data_point
	
	line_y = @graph_top + 
	  (@graph_height - data_point * @graph_height)
	line_x = offset + increment * (point_index)

	if prev_x
	  draw_ldata_line(attrs, prev_x, prev_y,
			  line_x, line_y, line_x, line_y) 
	else
	  draw_ldata_line(attrs, line_x, line_y,
			  line_x, line_y, line_x, line_y) 
	end

	prev_x = line_x
	prev_y = line_y
      end
      
    end
    @d.draw(@base_image)
  end

  def normalize(force=false)
    super
    self.normalize_ldata
  end
  
  def normalize_ldata
    return unless @has_ldata
    @ldata.each do |data_row|
      norm_data_points = []
      data_row[Gruff::Base::DATA_VALUES_INDEX].each do |data_point|
	if data_point.nil?
	  norm_data_points << nil
	else
	  norm_data_points << ((data_point.to_f - @minimum_value.to_f ) / @spread)
	end
      end
      @norm_ldata << [
	data_row[Gruff::Base::DATA_LABEL_INDEX], 
	norm_data_points,   # DATA_VALUES_INDEX
	data_row[Gruff::Base::DATA_COLOR_INDEX],
	data_row[Gruff::Base::DATA_ATTRS_INDEX]
      ]
    end

    # max size (num data points) of any of the ldata series
    @norm_ldata_max_size = @ldata.map{ |r| r[1].size }.max
  end
  
  
  def setup_legend_labels
    super
    @legend_labels += @ldata.collect {|item| item[Gruff::Base::DATA_LABEL_INDEX] }
  end


  # Draw a box or line for an entry in the legend, depending on whether
  # it is normal data or ldata
  def draw_legend_label_box(index,current_x_offset,current_y_offset)
    if(index < @data.length)
      super
    else
      draw_legend_label_box_as_line(index,current_x_offset,current_y_offset)
    end
  end

  # For ldata, draw the legend entry as a line
  def draw_legend_label_box_as_line(index,current_x_offset,current_y_offset)
    ldata_row = @norm_ldata[index - @data.length]
    x1 = current_x_offset
    y1 = current_y_offset - @legend_box_size / 2.0
    x2 = current_x_offset + @legend_box_size
    y2 = current_y_offset + @legend_box_size / 2.0
    
    draw_ldata_line(ldata_row[Gruff::Base::DATA_ATTRS_INDEX],
		    x1, y1, x2, y2, (x1 + x2)/2.0, (y1 + y2)/2.0)
  end

  
  def draw_ldata_line(attrs,x1,y1,x2,y2,px,py)
    color = attrs[:color]
    @d = @d.stroke color
    @d = @d.fill color
    @d = @d.stroke_opacity 1.0

    # ----------------------------------------
    # First the line

    line_width = attrs[:line_width].to_f
    if line_width > 0
      line_dash = []
      if attrs[:style]
	line_dash = style_to_dasharray(attrs[:style],line_width)
      end
      @d = @d.stroke_dasharray(*line_dash)
      
      max_line_width = @columns / (@norm_ldata_max_size * 4)
      lwidth = clip_value_if_greater_than(max_line_width, line_width)
      @d = @d.stroke_width lwidth
      @d = @d.line(x1,y1,x2,y2)
    end


    # ----------------------------------------
    # Second the point / circle
    
    dot_width = attrs[:dot_width].to_f
    if dot_width > 0
      # Reset so the circle doesn't look broken
      @d = @d.stroke_dasharray()

      max_dot_width = @columns / (@norm_ldata_max_size * 2.5)
      circle_radius = 
	clip_value_if_greater_than(max_dot_width, dot_width)
      @d = @d.circle(px, py, px - circle_radius, py)
    end
          

    # Reset opacity that the line stuff might have tweaked
    @d = @d.stroke_opacity 0.0
  end
  
    
  # Compute a dash pattern for linedata
  def style_to_dasharray(style,line_width)
    case style
    when Array
      [ style[0] ? style[0].to_f : line_width, 
        style[1] ? style[1].to_f : line_width ]
    when /dash/
      [ line_width * 2.5, line_width * 0.5 ]
    when /dot/
      [ line_width * 1.5, line_width * 1.5 ]
    when /^([0-9.]+)(\s*,\s*|\s+)([0-9.]+)$/
      [ $1.to_f, $3.to_f ]
    else
      [] # solid
    end
  end

  
end # Gruff::Base::LdataMixin



module Gruff::Base::LdataMixin
  # add support for trend / target lines on bars and stacked bars
  
  
  # These are for customizing the lines in line data
  attr_accessor :hide_dots, :hide_lines
  
  # for testability, expose these internals:
  attr_reader :has_ldata, :norm_ldata, :has_data
  
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
    @has_line_data = true
    
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
    @ldata = Array.new # for line data
    @norm_ldata = nil
    @ldata_offset_and_increment = Array.new
  end


  # This is added to deal with having more ldata than data
  def pre_normalize_ldata
    # See what the longest line data serie is
    max_ldata_num = 0
    @ldata.each { |row|
      # See how many data points we have in here
      max_ldata_num = row[Gruff::Base::DATA_VALUES_INDEX].size if
	max_ldata_num < row[Gruff::Base::DATA_VALUES_INDEX].size
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
      attrs = @ldata[row_index][Gruff::Base::DATA_ATTRS_INDEX]
      group = attrs[:group]
      color = attrs[:color]
      line_width = attrs[:line_width].to_f
      dot_width = attrs[:dot_width].to_f

      line_dash = []
      if attrs[:style]
        line_dash = style_to_dasharray(attrs[:style],line_width)
      end

      if @ldata_offset_and_increment[group].nil?
	puts "Invalid group #{group} given on line data. Resetting to group 0"
	group = 0
      end
      offset = @ldata_offset_and_increment[group][0] 
      increment = @ldata_offset_and_increment[group][1]
      
      ldata_row[1].each_with_index do |data_point, point_index|
        
        if line_dash
          @d.stroke_dasharray(*line_dash)
        end
        
        if ldata_row[1] and ldata_row[1][point_index]
          line_y = @graph_top + 
            (@graph_height - ldata_row[1][point_index] * @graph_height)
          @d = @d.stroke color
          @d = @d.fill color
          @d = @d.stroke_opacity 1.0
          @d = @d.stroke_width(clip_value_if_greater_than(@columns / 
                                                          (@norm_ldata.first[1].size * 4), line_width))
          
          line_x = offset + increment * (point_index)
          if !@hide_lines and !prev_x.nil? and !prev_y.nil? then
            @d = @d.line(prev_x, prev_y, line_x, line_y)
          end
          
          # Reset so the circle doesn't look broken
          @d.stroke_dasharray()               # Solid line

          circle_radius = 
            clip_value_if_greater_than(@columns / 
                                       (@norm_ldata.first[1].size * 2.5), 
                                       dot_width)
          if !hide_dots and dot_width > 0
            @d = @d.circle(line_x, line_y,
                           line_x - circle_radius, line_y)
          end
          
          prev_x = line_x
          prev_y = line_y
          
          # Reset opacity that the line stuff might have tweaked
          @d = @d.stroke_opacity 0.0
          
        end
        
      end
      
    end
    @d.draw(@base_image)
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
  
  def normalize(force=false)
    super
    self.normalize_ldata
  end
  
  def normalize_ldata
    # Same thing for line data
    @ldata.each do |data_row|
      @norm_ldata = []
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
        @norm_ldata << [data_row[Gruff::Base::DATA_LABEL_INDEX], 
          norm_data_points, data_row[Gruff::Base::DATA_COLOR_INDEX], data_row[Gruff::Base::DATA_ATTRS_INDEX]]
      end
    end
  end
  
  
  def setup_legend_labels
    super
    @legend_labels += @ldata.collect {|item| item[Gruff::Base::DATA_LABEL_INDEX] }
  end


  # Draw a box or line for an entry in the legend, depending on whether
  # it is normal data or ldata
  def draw_legend_label_box(index,current_x_offset,current_y_offset)
    # Put the line legend on its own line.
    if(index < @data.length)
      super
    else
      draw_legend_label_box_as_line(index,current_x_offset,current_y_offset)
    end
  end

  # For ldata, draw the legend entry as a line
  def draw_legend_label_box_as_line(index,current_x_offset,current_y_offset)
    @d = @d.stroke @ldata[index - @data.length][Gruff::Base::DATA_COLOR_INDEX]
    @d = @d.stroke_width 5
    @d = @d.line(current_x_offset, 
		 current_y_offset - @legend_box_size / 2.0, 
		 current_x_offset + @legend_box_size, 
		 current_y_offset + @legend_box_size / 2.0)
  end


end # Gruff::Base::LdataMixin


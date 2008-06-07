module Gruff
  class Base

    # You can set a theme manually. Assign a hash to this method before you
    # send your data.
    #
    #  graph.theme = {
    #    :colors => %w(orange purple green white red),
    #    :marker_color => 'blue',
    #    :background_colors => %w(black grey)
    #  }
    #
    # :background_image => 'squirrel.png' is also possible.
    #
    # (Or hopefully something better looking than that.)
    #
    def theme=(options)
      reset_themes()
      
      defaults = {
        :colors => ['black', 'white'],
        :additional_line_colors => [],
        :marker_color => 'white',
        :font_color => 'black',
        :background_colors => nil,
        :background_image => nil
      }
      @theme_options = defaults.merge options

      @colors = @theme_options[:colors]
      @marker_color = @theme_options[:marker_color]
      @font_color = @theme_options[:font_color] || @marker_color
      @additional_line_colors = @theme_options[:additional_line_colors]
      
      render_background
    end

    # A color scheme similar to the popular presentation software.
    def theme_keynote
      # Colors
      @blue = '#6886B4'
      @yellow = '#FDD84E'
      @green = '#72AE6E'
      @red = '#D1695E'
      @purple = '#8A6EAF'
      @orange = '#EFAA43'
      @white = 'white'
      @colors = [@yellow, @blue, @green, @red, @purple, @orange, @white]

      self.theme = {
        :colors => @colors,
        :marker_color => 'white',
        :font_color => 'white',
        :background_colors => ['black', '#4a465a']
      }
    end

    # A color scheme plucked from the colors on the popular usability blog.
    def theme_37signals
      # Colors
      @green = '#339933'
      @purple = '#cc99cc'
      @blue = '#336699'
      @yellow = '#FFF804'
      @red = '#ff0000'
      @orange = '#cf5910'
      @black = 'black'
      @colors = [@yellow, @blue, @green, @red, @purple, @orange, @black]

      self.theme = {
        :colors => @colors,
        :marker_color => 'black',
        :font_color => 'black',
        :background_colors => ['#d1edf5', 'white']
      }
    end

    # A color scheme from the colors used on the 2005 Rails keynote
    # presentation at RubyConf.
    def theme_rails_keynote
      # Colors
      @green = '#00ff00'
      @grey = '#333333'
      @orange = '#ff5d00'
      @red = '#f61100'
      @white = 'white'
      @light_grey = '#999999'
      @black = 'black'
      @colors = [@green, @grey, @orange, @red, @white, @light_grey, @black]
      
      self.theme = {
        :colors => @colors,
        :marker_color => 'white',
        :font_color => 'white',
        :background_colors => ['#0083a3', '#0083a3']
      }
    end

    # A color scheme similar to that used on the popular podcast site.
    def theme_odeo
      # Colors
      @grey = '#202020'
      @white = 'white'
      @dark_pink = '#a21764'
      @green = '#8ab438'
      @light_grey = '#999999'
      @dark_blue = '#3a5b87'
      @black = 'black'
      @colors = [@grey, @white, @dark_blue, @dark_pink, @green, @light_grey, @black]
      
      self.theme = {
        :colors => @colors,
        :marker_color => 'white',
        :font_color => 'white',
        :background_colors => ['#ff47a4', '#ff1f81']
      }
    end

    # A pastel theme
    def theme_pastel
      # Colors
      @colors = [
          '#a9dada', # blue
          '#aedaa9', # green
          '#daaea9', # peach
          '#dadaa9', # yellow
          '#a9a9da', # dk purple
          '#daaeda', # purple
          '#dadada' # grey
        ]
      
      self.theme = {
        :colors => @colors,
        :marker_color => '#aea9a9', # Grey
        :font_color => 'black',
        :background_colors => 'white'
      }
    end

    # A greyscale theme
    def theme_greyscale
      # Colors
      @colors = [
          '#282828', # 
          '#383838', # 
          '#686868', # 
          '#989898', # 
          '#c8c8c8', # 
          '#e8e8e8', # 
        ]
      
      self.theme = {
        :colors => @colors,
        :marker_color => '#aea9a9', # Grey
        :font_color => 'black',
        :background_colors => 'white'
      }
    end

  end # Gruff::Base

end # Gruff

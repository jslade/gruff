
module Gruff::Base::SideMixin
  # Used by SideStackedBar and SideBar

  def draw_axis_labels
    @x_axis_label, @y_axis_label = [ @y_axis_label, @x_axis_label ]
    draw_x_axis_label
    draw_y_axis_label
  end


end

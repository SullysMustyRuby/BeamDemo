defmodule BeamDemoWeb.PageView do
  use BeamDemoWeb, :view

  alias BeamDemo.Utils

  def background_color do
    Utils.get_setting("default_backround_color")
  end
end

defmodule BeamDemoWeb.PageController do
  use BeamDemoWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end

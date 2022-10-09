defmodule BeamDemoWeb.PageController do
  use BeamDemoWeb, :controller

  alias BeamDemo.Utils

  @tables [
    BeamDemo.Accounts.Address,
    BeamDemo.Accounts.User,
    BeamDemo.Accounts.UserToken,
    BeamDemo.Utils.Setting,
    BeamDemo.Utils.StateCode
  ]

  def index(conn, _params) do
    conn
    |> assign(:tables, @tables)
    |> assign(:class, Utils.get_setting_value!("hero_css"))
    |> render("index.html")
  end
end

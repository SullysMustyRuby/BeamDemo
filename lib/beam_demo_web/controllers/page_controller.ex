defmodule BeamDemoWeb.PageController do
  use BeamDemoWeb, :controller

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
    |> render("index.html")
  end
end

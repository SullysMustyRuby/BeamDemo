defmodule BeamDemoWeb.DbUserAuthLive do
  import Phoenix.LiveView

  alias BeamDemo.Accounts

  def on_mount(_, params, %{"db_user_token" => db_user_token} = _session, socket) do
    socket =
      socket
      |> assign(:current_db_user, Accounts.get_db_user_by_session_token(db_user_token))

    if socket.assigns.current_db_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end

  def on_mount(_, params, %{"am_user_token" => am_user_token} = _session, socket) do
    socket =
      socket
      |> assign(:current_am_user, Accounts.get_am_user_by_session_token(am_user_token))

    if socket.assigns.current_am_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end
end

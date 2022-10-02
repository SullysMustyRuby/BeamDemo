defmodule BeamDemoWeb.UserAuthLive do
  import Phoenix.LiveView

  alias BeamDemo.Accounts

  def on_mount(_, params, %{"user_token" => user_token} = _session, socket) do
    socket =
      socket
      |> assign(:current_user, Accounts.get_user_by_session_token(user_token))

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/login")}
    end
  end
end

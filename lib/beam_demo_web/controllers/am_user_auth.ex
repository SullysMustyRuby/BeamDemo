defmodule BeamDemoWeb.AmUserAuth do
  import Plug.Conn
  import Phoenix.Controller

  alias BeamDemo.Accounts
  alias BeamDemoWeb.Router.Helpers, as: Routes

  # Make the remember me cookie valid for 60 days.
  # If you want bump or reduce this value, also change
  # the token expiry itself in AmUserToken.
  @max_age 60 * 60 * 24 * 60
  @remember_me_cookie "_beam_demo_web_user_remember_me"
  @remember_me_options [sign: true, max_age: @max_age, same_site: "Lax"]

  @doc """
  Logs the am_user in.

  It renews the session ID and clears the whole session
  to avoid fixation attacks. See the renew_session
  function to customize this behaviour.

  It also sets a `:live_socket_id` key in the session,
  so LiveView sessions are identified and automatically
  disconnected on log out. The line can be safely removed
  if you are not using LiveView.
  """
  def log_in_am_user(conn, am_user, params \\ %{}) do
    token = Accounts.generate_am_user_session_token(am_user)
    user_return_to = get_session(conn, :user_return_to)

    conn
    |> renew_session()
    |> put_session(:user_token, token)
    |> put_session(:context, :am_user)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
    |> maybe_write_remember_me_cookie(token, params)
    |> redirect(to: user_return_to || signed_in_path(conn))
  end

  defp maybe_write_remember_me_cookie(conn, token, %{"remember_me" => "true"}) do
    put_resp_cookie(conn, @remember_me_cookie, token, @remember_me_options)
  end

  defp maybe_write_remember_me_cookie(conn, _token, _params) do
    conn
  end

  defp renew_session(conn) do
    conn
    |> configure_session(renew: true)
    |> clear_session()
  end

  @doc """
  Logs the am_user out.

  It clears all session data for safety. See renew_session.
  """
  def log_out_am_user(conn) do
    am_user_token = get_session(conn, :user_token)
    am_user_token && Accounts.delete_am_session_token(am_user_token)

    if live_socket_id = get_session(conn, :live_socket_id) do
      BeamDemoWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn
    |> renew_session()
    |> delete_resp_cookie(@remember_me_cookie)
    |> redirect(to: "/")
  end

  @doc """
  Authenticates the am_user by looking into the session
  and remember me token.
  """
  def fetch_current_am_user(conn, _opts) do
    {am_user_token, conn} = ensure_am_user_token(conn)
    am_user = am_user_token && Accounts.get_am_user_by_session_token(am_user_token)

    conn
    |> assign(:current_user, am_user)
    |> assign(:context, :am_user)
  end

  defp ensure_am_user_token(conn) do
    if am_user_token = get_session(conn, :user_token) do
      {am_user_token, conn}
    else
      conn = fetch_cookies(conn, signed: [@remember_me_cookie])

      if am_user_token = conn.cookies[@remember_me_cookie] do
        new_session =
          conn
          |> put_session(:user_token, am_user_token)
          |> assign(:context, :am_user)

        {am_user_token, new_session}
      else
        {nil, conn}
      end
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: "/"
end

defmodule BeamDemoWeb.DbUserAuthTest do
  use BeamDemoWeb.ConnCase, async: true

  alias BeamDemo.Accounts
  alias BeamDemoWeb.DbUserAuth
  import BeamDemo.AccountsFixtures

  @remember_me_cookie "_beam_demo_web_db_user_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, BeamDemoWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{db_user: db_user_fixture(), conn: conn}
  end

  describe "log_in_db_user/3" do
    test "stores the db_user token in the session", %{conn: conn, db_user: db_user} do
      conn = DbUserAuth.log_in_db_user(conn, db_user)
      assert token = get_session(conn, :db_user_token)
      assert get_session(conn, :live_socket_id) == "users_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Accounts.get_db_user_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, db_user: db_user} do
      conn = conn |> put_session(:to_be_removed, "value") |> DbUserAuth.log_in_db_user(db_user)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, db_user: db_user} do
      conn = conn |> put_session(:db_user_return_to, "/hello") |> DbUserAuth.log_in_db_user(db_user)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, db_user: db_user} do
      conn = conn |> fetch_cookies() |> DbUserAuth.log_in_db_user(db_user, %{"remember_me" => "true"})
      assert get_session(conn, :db_user_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :db_user_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_db_user/1" do
    test "erases session and cookies", %{conn: conn, db_user: db_user} do
      db_user_token = Accounts.generate_db_user_session_token(db_user)

      conn =
        conn
        |> put_session(:db_user_token, db_user_token)
        |> put_req_cookie(@remember_me_cookie, db_user_token)
        |> fetch_cookies()
        |> DbUserAuth.log_out_db_user()

      refute get_session(conn, :db_user_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Accounts.get_db_user_by_session_token(db_user_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "users_sessions:abcdef-token"
      BeamDemoWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> DbUserAuth.log_out_db_user()

      assert_receive %Phoenix.Socket.Broadcast{event: "disconnect", topic: ^live_socket_id}
    end

    test "works even if db_user is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> DbUserAuth.log_out_db_user()
      refute get_session(conn, :db_user_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_db_user/2" do
    test "authenticates db_user from session", %{conn: conn, db_user: db_user} do
      db_user_token = Accounts.generate_db_user_session_token(db_user)
      conn = conn |> put_session(:db_user_token, db_user_token) |> DbUserAuth.fetch_current_db_user([])
      assert conn.assigns.current_db_user.id == db_user.id
    end

    test "authenticates db_user from cookies", %{conn: conn, db_user: db_user} do
      logged_in_conn =
        conn |> fetch_cookies() |> DbUserAuth.log_in_db_user(db_user, %{"remember_me" => "true"})

      db_user_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> DbUserAuth.fetch_current_db_user([])

      assert get_session(conn, :db_user_token) == db_user_token
      assert conn.assigns.current_db_user.id == db_user.id
    end

    test "does not authenticate if data is missing", %{conn: conn, db_user: db_user} do
      _ = Accounts.generate_db_user_session_token(db_user)
      conn = DbUserAuth.fetch_current_db_user(conn, [])
      refute get_session(conn, :db_user_token)
      refute conn.assigns.current_db_user
    end
  end

  describe "redirect_if_db_user_is_authenticated/2" do
    test "redirects if db_user is authenticated", %{conn: conn, db_user: db_user} do
      conn = conn |> assign(:current_db_user, db_user) |> DbUserAuth.redirect_if_db_user_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if db_user is not authenticated", %{conn: conn} do
      conn = DbUserAuth.redirect_if_db_user_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_db_user/2" do
    test "redirects if db_user is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> DbUserAuth.require_authenticated_db_user([])
      assert conn.halted
      assert redirected_to(conn) == Routes.db_user_session_path(conn, :new)
      assert get_flash(conn, :error) == "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | path_info: ["foo"], query_string: ""}
        |> fetch_flash()
        |> DbUserAuth.require_authenticated_db_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :db_user_return_to) == "/foo"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar=baz"}
        |> fetch_flash()
        |> DbUserAuth.require_authenticated_db_user([])

      assert halted_conn.halted
      assert get_session(halted_conn, :db_user_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | path_info: ["foo"], query_string: "bar", method: "POST"}
        |> fetch_flash()
        |> DbUserAuth.require_authenticated_db_user([])

      assert halted_conn.halted
      refute get_session(halted_conn, :db_user_return_to)
    end

    test "does not redirect if db_user is authenticated", %{conn: conn, db_user: db_user} do
      conn = conn |> assign(:current_db_user, db_user) |> DbUserAuth.require_authenticated_db_user([])
      refute conn.halted
      refute conn.status
    end
  end
end

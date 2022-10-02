defmodule BeamDemoWeb.DbUserSessionControllerTest do
  use BeamDemoWeb.ConnCase, async: true

  import BeamDemo.AccountsFixtures

  setup do
    %{db_user: db_user_fixture()}
  end

  describe "GET /users/log_in" do
    test "renders log in page", %{conn: conn} do
      conn = get(conn, Routes.db_user_session_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Register</a>"
      assert response =~ "Forgot your password?</a>"
    end

    test "redirects if already logged in", %{conn: conn, db_user: db_user} do
      conn = conn |> log_in_db_user(db_user) |> get(Routes.db_user_session_path(conn, :new))
      assert redirected_to(conn) == "/"
    end
  end

  describe "POST /users/log_in" do
    test "logs the db_user in", %{conn: conn, db_user: db_user} do
      conn =
        post(conn, Routes.db_user_session_path(conn, :create), %{
          "db_user" => %{"email" => db_user.email, "password" => valid_db_user_password()}
        })

      assert get_session(conn, :db_user_token)
      assert redirected_to(conn) == "/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, "/")
      response = html_response(conn, 200)
      assert response =~ db_user.email
      assert response =~ "Settings</a>"
      assert response =~ "Log out</a>"
    end

    test "logs the db_user in with remember me", %{conn: conn, db_user: db_user} do
      conn =
        post(conn, Routes.db_user_session_path(conn, :create), %{
          "db_user" => %{
            "email" => db_user.email,
            "password" => valid_db_user_password(),
            "remember_me" => "true"
          }
        })

      assert conn.resp_cookies["_beam_demo_web_db_user_remember_me"]
      assert redirected_to(conn) == "/"
    end

    test "logs the db_user in with return to", %{conn: conn, db_user: db_user} do
      conn =
        conn
        |> init_test_session(db_user_return_to: "/foo/bar")
        |> post(Routes.db_user_session_path(conn, :create), %{
          "db_user" => %{
            "email" => db_user.email,
            "password" => valid_db_user_password()
          }
        })

      assert redirected_to(conn) == "/foo/bar"
    end

    test "emits error message with invalid credentials", %{conn: conn, db_user: db_user} do
      conn =
        post(conn, Routes.db_user_session_path(conn, :create), %{
          "db_user" => %{"email" => db_user.email, "password" => "invalid_password"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Log in</h1>"
      assert response =~ "Invalid email or password"
    end
  end

  describe "DELETE /users/log_out" do
    test "logs the db_user out", %{conn: conn, db_user: db_user} do
      conn = conn |> log_in_db_user(db_user) |> delete(Routes.db_user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :db_user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the db_user is not logged in", %{conn: conn} do
      conn = delete(conn, Routes.db_user_session_path(conn, :delete))
      assert redirected_to(conn) == "/"
      refute get_session(conn, :db_user_token)
      assert get_flash(conn, :info) =~ "Logged out successfully"
    end
  end
end

defmodule BeamDemoWeb.DbUserConfirmationControllerTest do
  use BeamDemoWeb.ConnCase, async: true

  alias BeamDemo.Accounts
  alias BeamDemo.Repo
  import BeamDemo.AccountsFixtures

  setup do
    %{db_user: db_user_fixture()}
  end

  describe "GET /users/confirm" do
    test "renders the resend confirmation page", %{conn: conn} do
      conn = get(conn, Routes.db_user_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /users/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, db_user: db_user} do
      conn =
        post(conn, Routes.db_user_confirmation_path(conn, :create), %{
          "db_user" => %{"email" => db_user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Accounts.DbUserToken, db_user_id: db_user.id).context == "confirm"
    end

    test "does not send confirmation token if Db user is confirmed", %{conn: conn, db_user: db_user} do
      Repo.update!(Accounts.DbUser.confirm_changeset(db_user))

      conn =
        post(conn, Routes.db_user_confirmation_path(conn, :create), %{
          "db_user" => %{"email" => db_user.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Accounts.DbUserToken, db_user_id: db_user.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.db_user_confirmation_path(conn, :create), %{
          "db_user" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Accounts.DbUserToken) == []
    end
  end

  describe "GET /users/confirm/:token" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.db_user_confirmation_path(conn, :edit, "some-token"))
      response = html_response(conn, 200)
      assert response =~ "<h1>Confirm account</h1>"

      form_action = Routes.db_user_confirmation_path(conn, :update, "some-token")
      assert response =~ "action=\"#{form_action}\""
    end
  end

  describe "POST /users/confirm/:token" do
    test "confirms the given token once", %{conn: conn, db_user: db_user} do
      token =
        extract_db_user_token(fn url ->
          Accounts.deliver_db_user_confirmation_instructions(db_user, url)
        end)

      conn = post(conn, Routes.db_user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Db user confirmed successfully"
      assert Accounts.get_db_user!(db_user.id).confirmed_at
      refute get_session(conn, :db_user_token)
      assert Repo.all(Accounts.DbUserToken) == []

      # When not logged in
      conn = post(conn, Routes.db_user_confirmation_path(conn, :update, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Db user confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_db_user(db_user)
        |> post(Routes.db_user_confirmation_path(conn, :update, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, db_user: db_user} do
      conn = post(conn, Routes.db_user_confirmation_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Db user confirmation link is invalid or it has expired"
      refute Accounts.get_db_user!(db_user.id).confirmed_at
    end
  end
end

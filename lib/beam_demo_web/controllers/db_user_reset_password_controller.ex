defmodule BeamDemoWeb.DbUserResetPasswordController do
  use BeamDemoWeb, :controller

  alias BeamDemo.Accounts

  plug :get_db_user_by_reset_password_token when action in [:edit, :update]

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"db_user" => %{"email" => email}}) do
    if db_user = Accounts.get_db_user_by_email(email) do
      Accounts.deliver_db_user_reset_password_instructions(
        db_user,
        &Routes.db_user_reset_password_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system, you will receive instructions to reset your password shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, _params) do
    render(conn, "edit.html", changeset: Accounts.change_db_user_password(conn.assigns.db_user))
  end

  # Do not log in the db_user after reset password to avoid a
  # leaked token giving the db_user access to the account.
  def update(conn, %{"db_user" => db_user_params}) do
    case Accounts.reset_db_user_password(conn.assigns.db_user, db_user_params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Password reset successfully.")
        |> redirect(to: Routes.db_user_session_path(conn, :new))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  defp get_db_user_by_reset_password_token(conn, _opts) do
    %{"token" => token} = conn.params

    if db_user = Accounts.get_db_user_by_reset_password_token(token) do
      conn |> assign(:db_user, db_user) |> assign(:token, token)
    else
      conn
      |> put_flash(:error, "Reset password link is invalid or it has expired.")
      |> redirect(to: "/")
      |> halt()
    end
  end
end

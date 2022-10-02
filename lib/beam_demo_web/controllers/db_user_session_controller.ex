defmodule BeamDemoWeb.DbUserSessionController do
  use BeamDemoWeb, :controller

  alias BeamDemo.Accounts
  alias BeamDemoWeb.DbUserAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"db_user" => db_user_params}) do
    %{"email" => email, "password" => password} = db_user_params

    if db_user = Accounts.get_db_user_by_email_and_password(email, password) do
      conn
      |> DbUserAuth.log_in_db_user(db_user, db_user_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> DbUserAuth.log_out_db_user()
  end
end

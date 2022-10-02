defmodule BeamDemoWeb.DbUserConfirmationController do
  use BeamDemoWeb, :controller

  alias BeamDemo.Accounts

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def create(conn, %{"db_user" => %{"email" => email}}) do
    if db_user = Accounts.get_db_user_by_email(email) do
      Accounts.deliver_db_user_confirmation_instructions(
        db_user,
        &Routes.db_user_confirmation_url(conn, :edit, &1)
      )
    end

    conn
    |> put_flash(
      :info,
      "If your email is in our system and it has not been confirmed yet, " <>
        "you will receive an email with instructions shortly."
    )
    |> redirect(to: "/")
  end

  def edit(conn, %{"token" => token}) do
    render(conn, "edit.html", token: token)
  end

  # Do not log in the db_user after confirmation to avoid a
  # leaked token giving the db_user access to the account.
  def update(conn, %{"token" => token}) do
    case Accounts.confirm_db_user(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Db user confirmed successfully.")
        |> redirect(to: "/")

      :error ->
        # If there is a current db_user and the account was already confirmed,
        # then odds are that the confirmation link was already visited, either
        # by some automation or by the db_user themselves, so we redirect without
        # a warning message.
        case conn.assigns do
          %{current_db_user: %{confirmed_at: confirmed_at}} when not is_nil(confirmed_at) ->
            redirect(conn, to: "/")

          %{} ->
            conn
            |> put_flash(:error, "Db user confirmation link is invalid or it has expired.")
            |> redirect(to: "/")
        end
    end
  end
end

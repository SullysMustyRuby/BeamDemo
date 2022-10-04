defmodule BeamDemoWeb.UserRegistrationController do
  use BeamDemoWeb, :controller

  alias BeamDemo.Accounts
  alias BeamDemo.Accounts.User
  alias BeamDemoWeb.UserAuth

  def new(conn, _params) do
    conn
    |> assign(:error_messages, nil)
    |> render("new.html")
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User created successfully.")
        |> UserAuth.log_in_user(user)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end

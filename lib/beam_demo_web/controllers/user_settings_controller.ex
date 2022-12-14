defmodule BeamDemoWeb.UserSettingsController do
  use BeamDemoWeb, :controller

  alias BeamDemo.Accounts
  alias BeamDemoWeb.UserAuth

  def edit(conn, _params) do
    conn
    |> assign(:error_messages, nil)
    |> render("edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_user_email(user, password, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(
          :info,
          "Email updated!"
        )
        |> redirect(to: "/")

      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_user_password(user, password, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, "/")
        |> UserAuth.log_in_user(user)

      {:error, message} ->
        conn
        |> put_flash(:error, message)
        |> redirect(to: Routes.user_settings_path(conn, :edit))
    end
  end

  # def confirm_email(conn, %{"token" => token}) do
  #   case Accounts.update_user_email(conn.assigns.current_user, token) do
  #     :ok ->
  #       conn
  #       |> put_flash(:info, "Email changed successfully.")
  #       |> redirect(to: Routes.user_settings_path(conn, :edit))

  #     :error ->
  #       conn
  #       |> put_flash(:error, "Email change link is invalid or it has expired.")
  #       |> redirect(to: Routes.user_settings_path(conn, :edit))
  #   end
  # end

  # defp assign_email_and_password_changesets(conn, _opts) do
  #   user = conn.assigns.current_user

  #   conn
  #   |> assign(:email_changeset, Accounts.change_user_email(user))
  #   |> assign(:password_changeset, Accounts.change_user_password(user))
  # end
end

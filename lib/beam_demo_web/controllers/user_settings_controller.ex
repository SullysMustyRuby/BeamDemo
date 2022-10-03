defmodule BeamDemoWeb.UserSettingsController do
  use BeamDemoWeb, :controller

  alias BeamDemo.Accounts
  alias BeamDemoWeb.UserAuth

  # plug :assign_email_and_password_changesets

  def edit(conn, _params) do
    conn
    |> assign(:error_messages, nil)
    |> render("edit.html")
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.apply_am_user_email(user, password, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(
          :info,
          "Email updated!"
        )
        |> redirect(to: Routes.user_settings_path(conn, :edit))

      {:error, message} ->
        conn
        |> assign(:error_messages, message)
        |> render(conn, "edit.html")
    end
  end

  def update(conn, %{"action" => "update_password"} = params) do
    %{"current_password" => password, "user" => user_params} = params
    user = conn.assigns.current_user

    case Accounts.update_am_user_password(user, password, user_params) do
      {:ok, db_user} ->
        conn
        |> put_flash(:info, "Password updated successfully.")
        |> put_session(:user_return_to, Routes.user_settings_path(conn, :edit))
        |> UserAuth.log_in_am_user(db_user)

      {:error, message} ->
        conn
        |> assign(:error_messages, message)
        |> render(conn, "edit.html")
    end
  end

  # def confirm_email(conn, %{"token" => token}) do
  #   case Accounts.update_db_user_email(conn.assigns.current_db_user, token) do
  #     :ok ->
  #       conn
  #       |> put_flash(:info, "Email changed successfully.")
  #       |> redirect(to: Routes.user_settings_path(conn, :edit))

  #     :error ->
  #       conn
  #       |> put_flash(:error, "Email change link is invalid or it has expired.")
  #       |> redirect(to: Routes.db_user_settings_path(conn, :edit))
  #   end
  # end

  # defp assign_email_and_password_changesets(conn, _opts) do
  #   user = conn.assigns.current_user

  #   conn
  #   |> assign(:email_changeset, Accounts.change_am_user_email(user))
  #   |> assign(:password_changeset, Accounts.change_am_user_password(user))
  # end
end

defmodule BeamDemoWeb.SettingLive.FormComponent do
  use BeamDemoWeb, :live_component

  alias BeamDemo.Utils

  @impl true
  def update(%{setting: _setting} = assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("save", %{"setting" => setting_params}, socket) do
    save_setting(
      socket,
      socket.assigns.action,
      setting_params
    )
  end

  defp save_setting(socket, :edit, setting_params) do
    case Utils.update_setting(socket.assigns.setting, setting_params) do
      {:ok, _setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Setting updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, errors} ->
        {:noreply, assign(socket, :errors, errors)}
    end
  end

  defp save_setting(socket, :new, setting_params) do
    case Utils.create_setting(setting_params) do
      {:ok, _setting} ->
        {:noreply,
         socket
         |> put_flash(:info, "Setting created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, errors} ->
        {:noreply, assign(socket, :errors, errors)}
    end
  end
end

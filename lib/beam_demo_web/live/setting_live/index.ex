defmodule BeamDemoWeb.SettingLive.Index do
  use BeamDemoWeb, :live_view

  alias BeamDemo.Utils
  alias BeamDemo.Utils.Setting

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :settings, list_settings())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"name" => key_name}) do
    socket
    |> assign(:page_title, "Edit Setting")
    |> assign(:setting, Utils.get_setting!(key_name))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Setting")
    |> assign(:setting, %Setting{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing settings")
    |> assign(:setting, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => key_name}, socket) do
    setting = Utils.get_setting!(key_name)
    :ok = Utils.delete_setting(setting)

    {:noreply, assign(socket, :settings, list_settings())}
  end

  def handle_event("reload", _params, socket) do
    Utils.reload_settings()

    {:noreply, assign(socket, :settings, list_settings())}
  end

  defp list_settings do
    Utils.all_settings()
  end
end

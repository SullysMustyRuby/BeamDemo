defmodule BeamDemoWeb.SettingLive.Show do
  use BeamDemoWeb, :live_view

  alias BeamDemo.Utils

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"name" => key_name}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:setting, Utils.get_setting!(key_name))}
  end

  defp page_title(:show), do: "Show Setting"
  defp page_title(:edit), do: "Edit Setting"
end

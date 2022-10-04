defmodule BeamDemoWeb.AddressLive.Show do
  use BeamDemoWeb, :live_view

  alias BeamDemo.{Accounts, Utils}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"uuid" => uuid}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:address, Accounts.get_address!(uuid))
     |> assign(:states, Utils.all_state_codes())}
  end

  defp page_title(:show), do: "Show Address"
  defp page_title(:edit), do: "Edit Address"
end

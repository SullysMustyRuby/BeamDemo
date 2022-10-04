defmodule BeamDemoWeb.AddressLive.Index do
  use BeamDemoWeb, :live_view

  alias BeamDemo.{Accounts, Utils}
  alias BeamDemo.Accounts.Address

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:addresses, list_addresses(socket.assigns.current_user))
     |> assign(:states, Utils.all_state_codes())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"uuid" => uuid}) do
    socket
    |> assign(:page_title, "Edit Address")
    |> assign(:address, Accounts.get_address!(uuid))
    |> assign(:states, Utils.all_state_codes())
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Address1")
    |> assign(:address, %Address{})
    |> assign(:states, Utils.all_state_codes())
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Addresses")
    |> assign(:address, nil)
    |> assign(:states, Utils.all_state_codes())
  end

  @impl true
  def handle_event("delete", %{"id" => uuid}, socket) do
    address = Accounts.get_address!(uuid)
    :ok = Accounts.delete_address(address)

    {:noreply, assign(socket, :addresses, list_addresses(socket.assigns.current_user))}
  end

  defp list_addresses(current_user) do
    {:ok, addresses} = Accounts.list_addresses(%{user_uuid: current_user.uuid})
    addresses
  end
end

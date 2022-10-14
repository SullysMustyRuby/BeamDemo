defmodule BeamDemoWeb.AddressLive.FormComponent do
  use BeamDemoWeb, :live_component

  alias BeamDemo.Accounts

  @impl true
  def update(%{address: _address} = assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("save", %{"address" => address_params}, socket) do
    save_address(
      socket,
      socket.assigns.action,
      address_params
    )
  end

  defp save_address(socket, :edit, address_params) do
    case Accounts.update_address(socket.assigns.address, address_params) do
      {:ok, _address} ->
        {:noreply,
         socket
         |> put_flash(:info, "Address updated successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  defp save_address(socket, :new, address_params) do
    case Accounts.create_address(address_params) do
      {:ok, _address} ->
        {:noreply,
         socket
         |> put_flash(:info, "Address created successfully")
         |> push_redirect(to: socket.assigns.return_to)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end

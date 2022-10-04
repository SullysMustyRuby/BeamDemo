defmodule BeamDemo.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias BeamDemo.ActiveMemoryError

  alias BeamDemo.Accounts.{
    Address,
    AddressStore,
    User,
    UserStore,
    UserToken,
    UserTokenStore
  }

  def list_addresses(%{user_uuid: user_uuid}) do
    AddressStore.select(%{user_uuid: user_uuid})
  end

  def get_address!(uuid) do
    case AddressStore.one(%{uuid: uuid}) do
      {:ok, %Address{} = address} -> address
      _ -> raise ActiveMemoryError
    end
  end

  def get_address(uuid), do: AddressStore.one(%{uuid: uuid})

  def create_address(attrs \\ %{}) do
    %Address{}
    |> Address.changeset(attrs)
    |> AddressStore.write()
  end

  def update_address(%Address{} = address, attrs) do
    address
    |> Address.changeset(attrs)
    |> AddressStore.write()
  end

  def delete_address(%Address{} = address) do
    AddressStore.delete(address)
  end

  def get_user_by_email(email) when is_binary(email) do
    UserStore.one(%{email: email, deleted_at: nil})
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    with {:ok, user} <- get_user_by_email(email),
         true <- User.valid_password?(user, password) do
      user
    end
  end

  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> UserStore.write()
  end

  def apply_user_email(user, password, attrs) do
    if User.valid_password?(user, password) do
      user
      |> User.update_email_changeset(attrs)
      |> UserStore.write()
    end
  end

  def update_user_password(user, password, params) do
  end

  def generate_user_session_token(user) do
    with {token, user_token} <- UserToken.build_session_token(user.uuid),
         {:ok, _} <- UserTokenStore.write(user_token) do
      token
    end
  end

  def get_user_by_session_token(token) do
    with {:ok, %UserToken{user_uuid: user_uuid}} <- UserTokenStore.one(%{token: token}),
         {:ok, %User{} = user} <- UserStore.one(%{uuid: user_uuid}) do
      user
    else
      {:ok, nil} ->
        nil
    end
  end

  def delete_session_token(token) do
    UserTokenStore.withdraw(%{token: token})
    :ok
  end
end

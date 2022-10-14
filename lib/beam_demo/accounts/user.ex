defmodule BeamDemo.Accounts.User do
  use ActiveMemory.Table,
    type: :ets

  # options: Application.get_env(:beam_demo, :active_memory_options)

  attributes auto_generate_uuid: true do
    field :email
    field :hashed_password
    field :deleted_at
  end

  def registration_changeset(%__MODULE__{} = user, params) do
    params
    |> cast(user)
    |> maybe_hash_password()
    |> to_struct()
  end

  def update_email_changeset(%__MODULE__{} = user, %{"email" => email}) do
    %{user | email: email}
  end

  def update_password_changeset(%__MODULE__{}, %{
        "password" => password,
        "password_confirmation" => password
      }) do
    %{password: password, hashed_password: nil}
    |> maybe_hash_password()
    |> to_struct()
  end

  def update_password_changeset(_user, _params),
    do: {:error, "password and password_confirmation do not match"}

  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  defp cast(%{"email" => email, "password" => password}, user) do
    user_attrs = Map.from_struct(user)
    Enum.into(%{email: email, password: password}, user_attrs)
  end

  defp cast(attrs, user) do
    user_attrs = Map.from_struct(user)
    Enum.into(attrs, user_attrs)
  end

  defp maybe_hash_password(%{password: password, hashed_password: nil} = attrs) do
    hashed_password = Bcrypt.hash_pwd_salt(password)

    attrs
    |> Map.put(:hashed_password, hashed_password)
    |> Map.delete(:password)
  end

  defp maybe_hash_password(attrs), do: attrs

  defp to_struct(attrs) do
    Kernel.struct(__MODULE__, attrs)
  end
end

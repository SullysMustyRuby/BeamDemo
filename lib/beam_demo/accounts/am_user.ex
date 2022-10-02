defmodule BeamDemo.Accounts.AmUser do
  use ActiveMemory.Table

  attributes auto_generate_uuid: true do
    field :email
    field :hashed_password
    field :confirmed_at
  end

  @doc """
  A db_user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(%__MODULE__{} = am_user, attrs) do
    attrs
    |> cast(am_user)
    |> maybe_hash_password()
    |> to_struct()
  end

  def valid_password?(%__MODULE__{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  defp cast(attrs, am_user) do
    am_user_attrs = Map.from_struct(am_user)
    Enum.into(attrs, am_user_attrs)
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

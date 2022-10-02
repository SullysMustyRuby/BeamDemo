defmodule BeamDemo.Accounts.AmUserToken do
  use ActiveMemory.Table

  @hash_algorithm :sha256
  @rand_size 32

  # It is very important to keep the reset password token expiry short,
  # since someone with access to the email may take over the account.
  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @change_email_validity_in_days 7
  @session_validity_in_days 60

  attributes do
    field :token
    field :context
    field :sent_to
    field :am_user_uuid
    field :inserted_at
  end

  def build_session_token(am_user_uuid) do
    token = :crypto.strong_rand_bytes(@rand_size)

    {token,
     %__MODULE__{
       token: token,
       context: "session",
       am_user_uuid: am_user_uuid,
       inserted_at: unix_now()
     }}
  end

  defp unix_now do
    DateTime.utc_now()
    |> DateTime.to_unix()
  end
end

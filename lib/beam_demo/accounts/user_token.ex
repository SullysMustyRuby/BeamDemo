defmodule BeamDemo.Accounts.UserToken do
  use ActiveMemory.Table,
    options: Application.get_env(:beam_demo, :active_memory_options) ++ [ram_copies: []]

  @rand_size 32

  # It is very important to keep the reset password token expiry short,
  # since someone with access to the email may take over the account.
  @session_validity_in_seconds 60 * 60 * 12

  attributes do
    field :token
    field :context
    field :sent_to
    field :user_uuid
    field :expires_at
  end

  def build_session_token(user_uuid) do
    token = :crypto.strong_rand_bytes(@rand_size)

    {token,
     %__MODULE__{
       token: token,
       context: "session",
       user_uuid: user_uuid,
       expires_at: unix_now()
     }}
  end

  defp unix_now do
    DateTime.utc_now()
    |> DateTime.add(@session_validity_in_seconds, :second)
    |> DateTime.to_unix()
  end
end

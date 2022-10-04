defmodule BeamDemo.Accounts.UserTokenStore do
  use ActiveMemory.Store,
    table: BeamDemo.Accounts.UserToken,
    initial_state: {:initial_state, []}

  import ActiveMemory.Query

  alias BeamDemo.Utils

  def initial_state do
    refresh_seconds = Utils.get_setting_value!("token_refresh_seconds")
    Process.send_after(self(), :refresh, refresh_seconds * 1000)
    started_at = DateTime.utc_now()
    next_refresh = DateTime.add(started_at, refresh_seconds, :millisecond)
    {:ok, %{started_at: started_at, next_refresh: next_refresh}}
  end

  def handle_info(:refresh, state) do
    {:ok, bad_tokens} = select(expired_query())

    for bad_token <- bad_tokens do
      withdraw(bad_token)
    end

    refresh_seconds = Utils.get_setting_value!("token_refresh_seconds")
    next_refresh = DateTime.utc_now() |> DateTime.add(refresh_seconds, :millisecond)

    Process.send_after(self(), :refresh, refresh_seconds * 1000)

    {:noreply, Map.put(state, :next_refresh, next_refresh)}
  end

  defp expired_query do
    now = DateTime.utc_now() |> DateTime.to_unix()
    match(:expires_at >= now)
  end
end

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

  def refresh, do: GenServer.call(__MODULE__, :refresh)

  @impl true
  def handle_call(:refresh, _from, state) do
    next_refresh = refresh_tokens()

    {:reply, %{next_refresh: next_refresh}, Map.put(state, :next_refresh, next_refresh)}
  end

  @impl true
  def handle_info(:refresh, state) do
    next_refresh = refresh_tokens()

    {:noreply, Map.put(state, :next_refresh, next_refresh)}
  end

  defp refresh_tokens do
    {:ok, bad_tokens} = select(expired_query())

    for bad_token <- bad_tokens do
      delete(bad_token)
    end

    refresh_seconds = Utils.get_setting_value!("token_refresh_seconds")
    next_refresh = DateTime.utc_now() |> DateTime.add(refresh_seconds, :millisecond)

    Process.send_after(self(), :refresh, refresh_seconds * 1000)
    next_refresh
  end

  defp expired_query do
    now = DateTime.utc_now() |> DateTime.to_unix()
    match(:expires_at >= now)
  end
end

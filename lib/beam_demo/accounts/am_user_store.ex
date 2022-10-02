defmodule BeamDemo.Accounts.AmUserStore do
  use ActiveMemory.Store,
    table: BeamDemo.Accounts.AmUser,
    initial_state: {:seed_users, ["am_user_seeds.exs"]}

  alias BeamDemo.Accounts
  alias BeamDemo.Accounts.AmUser

  def seed_users(filename) do
    {seeds, _} =
      filename
      |> Path.expand(__DIR__)
      |> Code.eval_file()

    for seed <- seeds do
      case one(%{email: seed.email}) do
        {:ok, nil} -> Accounts.register_am_user(seed)
        {:ok, %AmUser{} = am_user} -> am_user
      end
    end

    {:ok, %{}}
  end
end

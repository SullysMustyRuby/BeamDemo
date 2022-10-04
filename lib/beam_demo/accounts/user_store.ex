defmodule BeamDemo.Accounts.UserStore do
  use ActiveMemory.Store,
    table: BeamDemo.Accounts.User,
    initial_state: {:seed_users, ["user_seeds.exs"]}

  alias BeamDemo.Accounts
  alias BeamDemo.Accounts.User

  def seed_users(filename) do
    {seeds, _} =
      filename
      |> Path.expand(:code.priv_dir(:beam_demo))
      |> Code.eval_file()

    for seed <- seeds do
      case one(%{email: seed.email}) do
        {:ok, nil} -> Accounts.register_user(seed)
        {:ok, %User{} = user} -> user
      end
    end

    {:ok, %{}}
  end
end

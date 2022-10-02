defmodule BeamDemo.Repo do
  use Ecto.Repo,
    otp_app: :beam_demo,
    adapter: Ecto.Adapters.Postgres
end

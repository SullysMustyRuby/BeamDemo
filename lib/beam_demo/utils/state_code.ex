defmodule BeamDemo.Utils.StateCode do
  use ActiveMemory.Table,
    options: Application.get_env(:beam_demo, :active_memory_options)

  attributes do
    field :code
    field :name
  end
end

defmodule BeamDemo.Utils.StateCode do
  use ActiveMemory.Table,
    type: :ets

  attributes do
    field :code
    field :name
  end
end

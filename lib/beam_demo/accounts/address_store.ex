defmodule BeamDemo.Accounts.AddressStore do
  use ActiveMemory.Store,
    table: BeamDemo.Accounts.Address
end

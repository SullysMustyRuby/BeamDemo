defmodule BeamDemo.Accounts.AmUserTokenStore do
  use ActiveMemory.Store,
    table: BeamDemo.Accounts.AmUserToken
end

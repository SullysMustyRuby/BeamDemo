defmodule BeamDemo.Utils.StateCodeStore do
  use ActiveMemory.Store,
    table: BeamDemo.Utils.StateCode,
    seed_file: Path.expand("state_code_seeds.exs", :code.priv_dir(:beam_demo))
end

defmodule BeamDemo.Utils.SettingStore do
  use ActiveMemory.Store,
    table: BeamDemo.Utils.Setting,
    seed_file: Path.expand("setting_seeds.exs", :code.priv_dir(:beam_demo))
end

defmodule BeamDemo.Utils.Setting do
  use ActiveMemory.Table,
    type: :ets

  # options: Application.get_env(:beam_demo, :active_memory_options)

  attributes do
    field :key_name
    field :value
  end

  def changeset(%__MODULE__{} = setting, attrs) do
    attrs
    |> cast(setting)
    |> to_struct()
  end

  defp cast(%{"key_name" => key_name, "value" => value}, setting) do
    setting_attrs = Map.from_struct(setting)
    Enum.into(%{key_name: key_name, value: value}, setting_attrs)
  end

  defp cast(%{key_name: _key_name, value: _value} = attrs, setting) do
    setting_attrs = Map.from_struct(setting)
    Enum.into(attrs, setting_attrs)
  end

  defp to_struct(attrs) do
    Kernel.struct(__MODULE__, attrs)
  end
end

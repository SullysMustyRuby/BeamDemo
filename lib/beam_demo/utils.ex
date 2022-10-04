defmodule BeamDemo.Utils do
  alias BeamDemo.ActiveMemoryError
  alias BeamDemo.Utils.{Setting, SettingStore, StateCodeStore}
  alias BeamDemo.ActiveMemoryError

  def all_state_codes do
    StateCodeStore.all()
    |> Enum.into([], & &1.code)
  end

  def all_settings, do: SettingStore.all()

  def get_setting(name) when is_binary(name) do
    SettingStore.one(%{key_name: name})
  end

  def get_setting!(name) do
    case get_setting(name) do
      {:ok, %Setting{} = setting} -> setting
      {:ok, nil} -> raise ActiveMemoryError
    end
  end

  def get_setting_value!(name) do
    case get_setting(name) do
      {:ok, %Setting{} = setting} -> setting.value
      {:ok, nil} -> raise ActiveMemoryError
    end
  end

  def create_setting(attrs) do
    %Setting{}
    |> Setting.changeset(attrs)
    |> SettingStore.write()
  end

  def update_setting(%Setting{} = setting, attrs) do
    setting
    |> Setting.changeset(attrs)
    |> SettingStore.write()
  end

  def delete_setting(%Setting{} = setting), do: SettingStore.delete(setting)

  def delete_setting(name) do
    case get_setting(name) do
      {:ok, %Setting{} = setting} -> SettingStore.delete(setting)
      _ -> :ok
    end
  end
end

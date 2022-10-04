defmodule BeamDemo.Accounts.Address do
  use ActiveMemory.Table

  attributes auto_generate_uuid: true do
    field :user_uuid
    field :street_1
    field :street_2
    field :city
    field :state_code
    field :zip_code
  end

  @doc false

  @doc false
  def changeset(address, attrs) do
    attrs
    |> cast(address)
    |> to_struct()
  end

  defp cast(
         %{
           "user_uuid" => user_uuid,
           "street_1" => street_1,
           "street_2" => street_2,
           "city" => city,
           "state_code" => state_code,
           "zip_code" => zip_code
         },
         address
       ) do
    address_attrs = Map.from_struct(address)

    Enum.into(
      %{
        user_uuid: user_uuid,
        street_1: street_1,
        street_2: street_2,
        city: city,
        state_code: state_code,
        zip_code: zip_code
      },
      address_attrs
    )
  end

  defp cast(attrs, address) do
    address_attrs = Map.from_struct(address)
    Enum.into(attrs, address_attrs)
  end

  defp to_struct(attrs) do
    Kernel.struct(__MODULE__, attrs)
  end
end

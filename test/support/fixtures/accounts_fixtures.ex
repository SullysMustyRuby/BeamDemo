defmodule BeamDemo.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BeamDemo.Accounts` context.
  """

  def unique_db_user_email, do: "db_user#{System.unique_integer()}@example.com"
  def valid_db_user_password, do: "hello world!"

  def valid_db_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_db_user_email(),
      password: valid_db_user_password()
    })
  end

  def db_user_fixture(attrs \\ %{}) do
    {:ok, db_user} =
      attrs
      |> valid_db_user_attributes()
      |> BeamDemo.Accounts.register_db_user()

    db_user
  end

  def extract_db_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end

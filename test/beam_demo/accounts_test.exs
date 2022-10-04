defmodule BeamDemo.AccountsTest do
  use BeamDemo.DataCase

  alias BeamDemo.Accounts

  import BeamDemo.AccountsFixtures
  alias BeamDemo.Accounts.{DbUser, DbUserToken}

  describe "get_db_user_by_email/1" do
    test "does not return the db_user if the email does not exist" do
      refute Accounts.get_db_user_by_email("unknown@example.com")
    end

    test "returns the db_user if the email exists" do
      %{id: id} = db_user = db_user_fixture()
      assert %DbUser{id: ^id} = Accounts.get_db_user_by_email(db_user.email)
    end
  end

  describe "get_db_user_by_email_and_password/2" do
    test "does not return the db_user if the email does not exist" do
      refute Accounts.get_db_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the db_user if the password is not valid" do
      db_user = db_user_fixture()
      refute Accounts.get_db_user_by_email_and_password(db_user.email, "invalid")
    end

    test "returns the db_user if the email and password are valid" do
      %{id: id} = db_user = db_user_fixture()

      assert %DbUser{id: ^id} =
               Accounts.get_db_user_by_email_and_password(db_user.email, valid_db_user_password())
    end
  end

  describe "get_db_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_db_user!(-1)
      end
    end

    test "returns the db_user with the given id" do
      %{id: id} = db_user = db_user_fixture()
      assert %DbUser{id: ^id} = Accounts.get_db_user!(db_user.id)
    end
  end

  describe "register_db_user/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_db_user(%{})

      assert %{
               password: ["can't be blank"],
               email: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} =
        Accounts.register_db_user(%{email: "not valid", password: "not valid"})

      assert %{
               email: ["must have the @ sign and no spaces"],
               password: ["should be at least 12 character(s)"]
             } = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_db_user(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates email uniqueness" do
      %{email: email} = db_user_fixture()
      {:error, changeset} = Accounts.register_db_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_db_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users with a hashed password" do
      email = unique_db_user_email()
      {:ok, db_user} = Accounts.register_db_user(valid_db_user_attributes(email: email))
      assert db_user.email == email
      assert is_binary(db_user.hashed_password)
      assert is_nil(db_user.confirmed_at)
      assert is_nil(db_user.password)
    end
  end

  describe "change_db_user_registration/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_db_user_registration(%DbUser{})
      assert changeset.required == [:password, :email]
    end

    test "allows fields to be set" do
      email = unique_db_user_email()
      password = valid_db_user_password()

      changeset =
        Accounts.change_db_user_registration(
          %DbUser{},
          valid_db_user_attributes(email: email, password: password)
        )

      assert changeset.valid?
      assert get_change(changeset, :email) == email
      assert get_change(changeset, :password) == password
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "change_db_user_email/2" do
    test "returns a db_user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_db_user_email(%DbUser{})
      assert changeset.required == [:email]
    end
  end

  describe "apply_db_user_email/3" do
    setup do
      %{db_user: db_user_fixture()}
    end

    test "requires email to change", %{db_user: db_user} do
      {:error, changeset} = Accounts.apply_db_user_email(db_user, valid_db_user_password(), %{})
      assert %{email: ["did not change"]} = errors_on(changeset)
    end

    test "validates email", %{db_user: db_user} do
      {:error, changeset} =
        Accounts.apply_db_user_email(db_user, valid_db_user_password(), %{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum value for email for security", %{db_user: db_user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.apply_db_user_email(db_user, valid_db_user_password(), %{email: too_long})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness", %{db_user: db_user} do
      %{email: email} = db_user_fixture()

      {:error, changeset} =
        Accounts.apply_db_user_email(db_user, valid_db_user_password(), %{email: email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "validates current password", %{db_user: db_user} do
      {:error, changeset} =
        Accounts.apply_db_user_email(db_user, "invalid", %{email: unique_db_user_email()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "applies the email without persisting it", %{db_user: db_user} do
      email = unique_db_user_email()

      {:ok, db_user} =
        Accounts.apply_db_user_email(db_user, valid_db_user_password(), %{email: email})

      assert db_user.email == email
      assert Accounts.get_db_user!(db_user.id).email != email
    end
  end

  describe "deliver_update_email_instructions/3" do
    setup do
      %{db_user: db_user_fixture()}
    end

    test "sends token through notification", %{db_user: db_user} do
      token =
        extract_db_user_token(fn url ->
          Accounts.deliver_update_email_instructions(db_user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert db_user_token = Repo.get_by(DbUserToken, token: :crypto.hash(:sha256, token))
      assert db_user_token.db_user_id == db_user.id
      assert db_user_token.sent_to == db_user.email
      assert db_user_token.context == "change:current@example.com"
    end
  end

  describe "update_db_user_email/2" do
    setup do
      db_user = db_user_fixture()
      email = unique_db_user_email()

      token =
        extract_db_user_token(fn url ->
          Accounts.deliver_update_email_instructions(
            %{db_user | email: email},
            db_user.email,
            url
          )
        end)

      %{db_user: db_user, token: token, email: email}
    end

    test "updates the email with a valid token", %{db_user: db_user, token: token, email: email} do
      assert Accounts.update_db_user_email(db_user, token) == :ok
      changed_db_user = Repo.get!(DbUser, db_user.id)
      assert changed_db_user.email != db_user.email
      assert changed_db_user.email == email
      assert changed_db_user.confirmed_at
      assert changed_db_user.confirmed_at != db_user.confirmed_at
      refute Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end

    test "does not update email with invalid token", %{db_user: db_user} do
      assert Accounts.update_db_user_email(db_user, "oops") == :error
      assert Repo.get!(DbUser, db_user.id).email == db_user.email
      assert Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end

    test "does not update email if db_user email changed", %{db_user: db_user, token: token} do
      assert Accounts.update_db_user_email(%{db_user | email: "current@example.com"}, token) ==
               :error

      assert Repo.get!(DbUser, db_user.id).email == db_user.email
      assert Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end

    test "does not update email if token expired", %{db_user: db_user, token: token} do
      {1, nil} = Repo.update_all(DbUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_db_user_email(db_user, token) == :error
      assert Repo.get!(DbUser, db_user.id).email == db_user.email
      assert Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end
  end

  describe "change_db_user_password/2" do
    test "returns a db_user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_db_user_password(%DbUser{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_db_user_password(%DbUser{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_db_user_password/3" do
    setup do
      %{db_user: db_user_fixture()}
    end

    test "validates password", %{db_user: db_user} do
      {:error, changeset} =
        Accounts.update_db_user_password(db_user, valid_db_user_password(), %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{db_user: db_user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_db_user_password(db_user, valid_db_user_password(), %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{db_user: db_user} do
      {:error, changeset} =
        Accounts.update_db_user_password(db_user, "invalid", %{password: valid_db_user_password()})

      assert %{current_password: ["is not valid"]} = errors_on(changeset)
    end

    test "updates the password", %{db_user: db_user} do
      {:ok, db_user} =
        Accounts.update_db_user_password(db_user, valid_db_user_password(), %{
          password: "new valid password"
        })

      assert is_nil(db_user.password)
      assert Accounts.get_db_user_by_email_and_password(db_user.email, "new valid password")
    end

    test "deletes all tokens for the given db_user", %{db_user: db_user} do
      _ = Accounts.generate_db_user_session_token(db_user)

      {:ok, _} =
        Accounts.update_db_user_password(db_user, valid_db_user_password(), %{
          password: "new valid password"
        })

      refute Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end
  end

  describe "generate_db_user_session_token/1" do
    setup do
      %{db_user: db_user_fixture()}
    end

    test "generates a token", %{db_user: db_user} do
      token = Accounts.generate_db_user_session_token(db_user)
      assert db_user_token = Repo.get_by(DbUserToken, token: token)
      assert db_user_token.context == "session"

      # Creating the same token for another db_user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%DbUserToken{
          token: db_user_token.token,
          db_user_id: db_user_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_db_user_by_session_token/1" do
    setup do
      db_user = db_user_fixture()
      token = Accounts.generate_db_user_session_token(db_user)
      %{db_user: db_user, token: token}
    end

    test "returns db_user by token", %{db_user: db_user, token: token} do
      assert session_db_user = Accounts.get_db_user_by_session_token(token)
      assert session_db_user.id == db_user.id
    end

    test "does not return db_user for invalid token" do
      refute Accounts.get_db_user_by_session_token("oops")
    end

    test "does not return db_user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(DbUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_db_user_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      db_user = db_user_fixture()
      token = Accounts.generate_db_user_session_token(db_user)
      assert Accounts.delete_db_session_token(token) == :ok
      refute Accounts.get_db_user_by_session_token(token)
    end
  end

  describe "deliver_db_user_confirmation_instructions/2" do
    setup do
      %{db_user: db_user_fixture()}
    end

    test "sends token through notification", %{db_user: db_user} do
      token =
        extract_db_user_token(fn url ->
          Accounts.deliver_db_user_confirmation_instructions(db_user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert db_user_token = Repo.get_by(DbUserToken, token: :crypto.hash(:sha256, token))
      assert db_user_token.db_user_id == db_user.id
      assert db_user_token.sent_to == db_user.email
      assert db_user_token.context == "confirm"
    end
  end

  describe "confirm_db_user/1" do
    setup do
      db_user = db_user_fixture()

      token =
        extract_db_user_token(fn url ->
          Accounts.deliver_db_user_confirmation_instructions(db_user, url)
        end)

      %{db_user: db_user, token: token}
    end

    test "confirms the email with a valid token", %{db_user: db_user, token: token} do
      assert {:ok, confirmed_db_user} = Accounts.confirm_db_user(token)
      assert confirmed_db_user.confirmed_at
      assert confirmed_db_user.confirmed_at != db_user.confirmed_at
      assert Repo.get!(DbUser, db_user.id).confirmed_at
      refute Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end

    test "does not confirm with invalid token", %{db_user: db_user} do
      assert Accounts.confirm_db_user("oops") == :error
      refute Repo.get!(DbUser, db_user.id).confirmed_at
      assert Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end

    test "does not confirm email if token expired", %{db_user: db_user, token: token} do
      {1, nil} = Repo.update_all(DbUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.confirm_db_user(token) == :error
      refute Repo.get!(DbUser, db_user.id).confirmed_at
      assert Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end
  end

  describe "deliver_db_user_reset_password_instructions/2" do
    setup do
      %{db_user: db_user_fixture()}
    end

    test "sends token through notification", %{db_user: db_user} do
      token =
        extract_db_user_token(fn url ->
          Accounts.deliver_db_user_reset_password_instructions(db_user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert db_user_token = Repo.get_by(DbUserToken, token: :crypto.hash(:sha256, token))
      assert db_user_token.db_user_id == db_user.id
      assert db_user_token.sent_to == db_user.email
      assert db_user_token.context == "reset_password"
    end
  end

  describe "get_db_user_by_reset_password_token/1" do
    setup do
      db_user = db_user_fixture()

      token =
        extract_db_user_token(fn url ->
          Accounts.deliver_db_user_reset_password_instructions(db_user, url)
        end)

      %{db_user: db_user, token: token}
    end

    test "returns the db_user with valid token", %{db_user: %{id: id}, token: token} do
      assert %DbUser{id: ^id} = Accounts.get_db_user_by_reset_password_token(token)
      assert Repo.get_by(DbUserToken, db_user_id: id)
    end

    test "does not return the db_user with invalid token", %{db_user: db_user} do
      refute Accounts.get_db_user_by_reset_password_token("oops")
      assert Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end

    test "does not return the db_user if token expired", %{db_user: db_user, token: token} do
      {1, nil} = Repo.update_all(DbUserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_db_user_by_reset_password_token(token)
      assert Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end
  end

  describe "reset_db_user_password/2" do
    setup do
      %{db_user: db_user_fixture()}
    end

    test "validates password", %{db_user: db_user} do
      {:error, changeset} =
        Accounts.reset_db_user_password(db_user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{db_user: db_user} do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.reset_db_user_password(db_user, %{password: too_long})
      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{db_user: db_user} do
      {:ok, updated_db_user} =
        Accounts.reset_db_user_password(db_user, %{password: "new valid password"})

      assert is_nil(updated_db_user.password)
      assert Accounts.get_db_user_by_email_and_password(db_user.email, "new valid password")
    end

    test "deletes all tokens for the given db_user", %{db_user: db_user} do
      _ = Accounts.generate_db_user_session_token(db_user)
      {:ok, _} = Accounts.reset_db_user_password(db_user, %{password: "new valid password"})
      refute Repo.get_by(DbUserToken, db_user_id: db_user.id)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%DbUser{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "addresses" do
    alias BeamDemo.Accounts.Address

    import BeamDemo.AccountsFixtures

    @invalid_attrs %{
      city: nil,
      state_code: nil,
      street_1: nil,
      street_2: nil,
      user_uuid: nil,
      zip_code: nil
    }

    test "list_addresses/0 returns all addresses" do
      address = address_fixture()
      assert Accounts.list_addresses() == [address]
    end

    test "get_address!/1 returns the address with given id" do
      address = address_fixture()
      assert Accounts.get_address!(address.id) == address
    end

    test "create_address/1 with valid data creates a address" do
      valid_attrs = %{
        city: "some city",
        state_code: "some state_code",
        street_1: "some street_1",
        street_2: "some street_2",
        user_uuid: "some user_uuid",
        zip_code: "some zip_code"
      }

      assert {:ok, %Address{} = address} = Accounts.create_address(valid_attrs)
      assert address.city == "some city"
      assert address.state_code == "some state_code"
      assert address.street_1 == "some street_1"
      assert address.street_2 == "some street_2"
      assert address.user_uuid == "some user_uuid"
      assert address.zip_code == "some zip_code"
    end

    test "create_address/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_address(@invalid_attrs)
    end

    test "update_address/2 with valid data updates the address" do
      address = address_fixture()

      update_attrs = %{
        city: "some updated city",
        state_code: "some updated state_code",
        street_1: "some updated street_1",
        street_2: "some updated street_2",
        user_uuid: "some updated user_uuid",
        zip_code: "some updated zip_code"
      }

      assert {:ok, %Address{} = address} = Accounts.update_address(address, update_attrs)
      assert address.city == "some updated city"
      assert address.state_code == "some updated state_code"
      assert address.street_1 == "some updated street_1"
      assert address.street_2 == "some updated street_2"
      assert address.user_uuid == "some updated user_uuid"
      assert address.zip_code == "some updated zip_code"
    end

    test "update_address/2 with invalid data returns error changeset" do
      address = address_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_address(address, @invalid_attrs)
      assert address == Accounts.get_address!(address.id)
    end

    test "delete_address/1 deletes the address" do
      address = address_fixture()
      assert {:ok, %Address{}} = Accounts.delete_address(address)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_address!(address.id) end
    end

    test "change_address/1 returns a address changeset" do
      address = address_fixture()
      assert %Ecto.Changeset{} = Accounts.change_address(address)
    end
  end
end

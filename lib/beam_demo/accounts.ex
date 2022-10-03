defmodule BeamDemo.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias BeamDemo.Repo

  alias BeamDemo.Accounts.{
    AmUser,
    AmUserStore,
    AmUserToken,
    AmUserTokenStore,
    DbUser,
    DbUserToken,
    DbUserNotifier
  }

  ## Database getters

  @doc """
  Gets a db_user by email.

  ## Examples

      iex> get_db_user_by_email("foo@example.com")
      %DbUser{}

      iex> get_db_user_by_email("unknown@example.com")
      nil

  """
  def get_db_user_by_email(email) when is_binary(email) do
    Repo.get_by(DbUser, email: email)
  end

  def get_am_user_by_email(email) when is_binary(email) do
    AmUserStore.one(%{email: email})
  end

  @doc """
  Gets a db_user by email and password.

  ## Examples

      iex> get_db_user_by_email_and_password("foo@example.com", "correct_password")
      %DbUser{}

      iex> get_db_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_db_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    db_user = Repo.get_by(DbUser, email: email)
    if DbUser.valid_password?(db_user, password), do: db_user
  end

  def get_am_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    with {:ok, am_user} <- get_am_user_by_email(email),
         true <- AmUser.valid_password?(am_user, password) do
      am_user
    end
  end

  @doc """
  Gets a single db_user.

  Raises `Ecto.NoResultsError` if the DbUser does not exist.

  ## Examples

      iex> get_db_user!(123)
      %DbUser{}

      iex> get_db_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_db_user!(id), do: Repo.get!(DbUser, id)

  ## Db user registration

  @doc """
  Registers a db_user.

  ## Examples

      iex> register_db_user(%{field: value})
      {:ok, %DbUser{}}

      iex> register_db_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_db_user(attrs) do
    %DbUser{}
    |> DbUser.registration_changeset(attrs)
    |> Repo.insert()
  end

  def register_am_user(attrs) do
    %AmUser{}
    |> AmUser.registration_changeset(attrs)
    |> AmUserStore.write()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking db_user changes.

  ## Examples

      iex> change_db_user_registration(db_user)
      %Ecto.Changeset{data: %DbUser{}}

  """
  def change_db_user_registration(%DbUser{} = db_user, attrs \\ %{}) do
    DbUser.registration_changeset(db_user, attrs, hash_password: false)
  end

  ## Settings

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the db_user email.

  ## Examples

      iex> change_db_user_email(db_user)
      %Ecto.Changeset{data: %DbUser{}}

  """
  def change_db_user_email(db_user, attrs \\ %{}) do
    DbUser.email_changeset(db_user, attrs)
  end

  @doc """
  Emulates that the email will change without actually changing
  it in the database.

  ## Examples

      iex> apply_db_user_email(db_user, "valid password", %{email: ...})
      {:ok, %DbUser{}}

      iex> apply_db_user_email(db_user, "invalid password", %{email: ...})
      {:error, %Ecto.Changeset{}}

  """
  def apply_db_user_email(db_user, password, attrs) do
    db_user
    |> DbUser.email_changeset(attrs)
    |> DbUser.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  def apply_am_user_email(am_user, password, attrs) do
    if AmUser.valid_password?(am_user, password) do
      am_user
      |> update_email_changeset
      |> AmUserStore.write()
    end
  end

  @doc """
  Updates the db_user email using the given token.

  If the token matches, the db_user email is updated and the token is deleted.
  The confirmed_at date is also updated to the current time.
  """
  def update_db_user_email(db_user, token) do
    context = "change:#{db_user.email}"

    with {:ok, query} <- DbUserToken.verify_change_email_token_query(token, context),
         %DbUserToken{sent_to: email} <- Repo.one(query),
         {:ok, _} <- Repo.transaction(db_user_email_multi(db_user, email, context)) do
      :ok
    else
      _ -> :error
    end
  end

  defp db_user_email_multi(db_user, email, context) do
    changeset =
      db_user
      |> DbUser.email_changeset(%{email: email})
      |> DbUser.confirm_changeset()

    Ecto.Multi.new()
    |> Ecto.Multi.update(:db_user, changeset)
    |> Ecto.Multi.delete_all(:tokens, DbUserToken.db_user_and_contexts_query(db_user, [context]))
  end

  @doc """
  Delivers the update email instructions to the given db_user.

  ## Examples

      iex> deliver_update_email_instructions(db_user, current_email, &Routes.db_user_update_email_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_update_email_instructions(%DbUser{} = db_user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, db_user_token} =
      DbUserToken.build_email_token(db_user, "change:#{current_email}")

    Repo.insert!(db_user_token)

    DbUserNotifier.deliver_update_email_instructions(
      db_user,
      update_email_url_fun.(encoded_token)
    )
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the db_user password.

  ## Examples

      iex> change_db_user_password(db_user)
      %Ecto.Changeset{data: %DbUser{}}

  """
  def change_db_user_password(db_user, attrs \\ %{}) do
    DbUser.password_changeset(db_user, attrs, hash_password: false)
  end

  @doc """
  Updates the db_user password.

  ## Examples

      iex> update_db_user_password(db_user, "valid password", %{password: ...})
      {:ok, %DbUser{}}

      iex> update_db_user_password(db_user, "invalid password", %{password: ...})
      {:error, %Ecto.Changeset{}}

  """
  def update_db_user_password(db_user, password, attrs) do
    changeset =
      db_user
      |> DbUser.password_changeset(attrs)
      |> DbUser.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:db_user, changeset)
    |> Ecto.Multi.delete_all(:tokens, DbUserToken.db_user_and_contexts_query(db_user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{db_user: db_user}} -> {:ok, db_user}
      {:error, :db_user, changeset, _} -> {:error, changeset}
    end
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_db_user_session_token(db_user) do
    {token, db_user_token} = DbUserToken.build_session_token(db_user)
    Repo.insert!(db_user_token)
    token
  end

  def generate_am_user_session_token(am_user) do
    with {token, am_user_token} <- AmUserToken.build_session_token(am_user.uuid),
         {:ok, _} <- AmUserTokenStore.write(am_user_token) do
      token
    end
  end

  @doc """
  Gets the db_user with the given signed token.
  """
  def get_db_user_by_session_token(token) do
    {:ok, query} = DbUserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  def get_am_user_by_session_token(token) do
    with {:ok, %AmUserToken{am_user_uuid: am_user_uuid}} <- AmUserTokenStore.one(%{token: token}),
         {:ok, %AmUser{} = am_user} <- AmUserStore.one(%{uuid: am_user_uuid}) do
      am_user
    else
      {:ok, nil} ->
        nil
    end
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_db_session_token(token) do
    Repo.delete_all(DbUserToken.token_and_context_query(token, "session"))
    :ok
  end

  def delete_am_session_token(token) do
    AmUserTokenStore.withdraw(%{token: token})
    :ok
  end

  ## Confirmation

  @doc """
  Delivers the confirmation email instructions to the given db_user.

  ## Examples

      iex> deliver_db_user_confirmation_instructions(db_user, &Routes.db_user_confirmation_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

      iex> deliver_db_user_confirmation_instructions(confirmed_db_user, &Routes.db_user_confirmation_url(conn, :edit, &1))
      {:error, :already_confirmed}

  """
  def deliver_db_user_confirmation_instructions(%DbUser{} = db_user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if db_user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, db_user_token} = DbUserToken.build_email_token(db_user, "confirm")
      Repo.insert!(db_user_token)

      DbUserNotifier.deliver_confirmation_instructions(
        db_user,
        confirmation_url_fun.(encoded_token)
      )
    end
  end

  @doc """
  Confirms a db_user by the given token.

  If the token matches, the db_user account is marked as confirmed
  and the token is deleted.
  """
  def confirm_db_user(token) do
    with {:ok, query} <- DbUserToken.verify_email_token_query(token, "confirm"),
         %DbUser{} = db_user <- Repo.one(query),
         {:ok, %{db_user: db_user}} <- Repo.transaction(confirm_db_user_multi(db_user)) do
      {:ok, db_user}
    else
      _ -> :error
    end
  end

  defp confirm_db_user_multi(db_user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:db_user, DbUser.confirm_changeset(db_user))
    |> Ecto.Multi.delete_all(
      :tokens,
      DbUserToken.db_user_and_contexts_query(db_user, ["confirm"])
    )
  end

  ## Reset password

  @doc """
  Delivers the reset password email to the given db_user.

  ## Examples

      iex> deliver_db_user_reset_password_instructions(db_user, &Routes.db_user_reset_password_url(conn, :edit, &1))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_db_user_reset_password_instructions(%DbUser{} = db_user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, db_user_token} = DbUserToken.build_email_token(db_user, "reset_password")
    Repo.insert!(db_user_token)

    DbUserNotifier.deliver_reset_password_instructions(
      db_user,
      reset_password_url_fun.(encoded_token)
    )
  end

  @doc """
  Gets the db_user by reset password token.

  ## Examples

      iex> get_db_user_by_reset_password_token("validtoken")
      %DbUser{}

      iex> get_db_user_by_reset_password_token("invalidtoken")
      nil

  """
  def get_db_user_by_reset_password_token(token) do
    with {:ok, query} <- DbUserToken.verify_email_token_query(token, "reset_password"),
         %DbUser{} = db_user <- Repo.one(query) do
      db_user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the db_user password.

  ## Examples

      iex> reset_db_user_password(db_user, %{password: "new long password", password_confirmation: "new long password"})
      {:ok, %DbUser{}}

      iex> reset_db_user_password(db_user, %{password: "valid", password_confirmation: "not the same"})
      {:error, %Ecto.Changeset{}}

  """
  def reset_db_user_password(db_user, attrs) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:db_user, DbUser.password_changeset(db_user, attrs))
    |> Ecto.Multi.delete_all(:tokens, DbUserToken.db_user_and_contexts_query(db_user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{db_user: db_user}} -> {:ok, db_user}
      {:error, :db_user, changeset, _} -> {:error, changeset}
    end
  end
end

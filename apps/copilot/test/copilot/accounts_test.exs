defmodule Copilot.AccountsTest do
  @moduledoc false

  use Copilot.DataCase, async: true

  alias Copilot.Accounts
  alias Copilot.Accounts.{User, UserToken}

  setup do
    %{user: insert(:user)}
  end

  describe "find_user_by_id!/1" do
    test "returns user", %{user: user} do
      assert %User{} = returned_user = Accounts.find_user_by_id!(user.id)
      assert returned_user.id == user.id
    end

    test "raises error when not found" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.find_user_by_id!(100_000)
      end
    end
  end

  describe "find_user_by_email/1" do
    test "returns nil with no results" do
      refute Accounts.find_user_by_email("no")
    end

    test "returns a matching user", %{user: user} do
      %User{} = returned_user = Accounts.find_user_by_email(user.email)

      assert returned_user.id == user.id
    end
  end

  describe "find_user_by_email_and_password/2" do
    test "returns nil with no matching email" do
      refute Accounts.find_user_by_email_and_password("no", "no")
    end

    test "returns nil with no matching password", %{user: user} do
      refute Accounts.find_user_by_email_and_password(user.email, "no")
    end

    test "returns a matching user", %{user: user} do
      %User{} = returned_user = Accounts.find_user_by_email_and_password(user.email, "copilot123")

      assert returned_user.id == user.id
    end
  end

  describe "create_user/3" do
    test "requires a name" do
      {:error, changeset} = Accounts.create_user(%{})

      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires an email" do
      {:error, changeset} = Accounts.create_user(%{})

      assert "can't be blank" in errors_on(changeset).email
    end

    test "requires an email be less than 160 characters" do
      {:error, changeset} = Accounts.create_user(%{email: String.duplicate("a", 175)})

      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "requires an email be formatted correctly" do
      {:error, changeset} = Accounts.create_user(%{email: "no"})

      assert "must have an @ sign and no spaces" in errors_on(changeset).email
    end

    test "requires an email be unique", %{user: user} do
      {:error, changeset} = Accounts.create_user(%{email: user.email})

      assert "has already been taken" in errors_on(changeset).email
    end

    test "requires a password" do
      {:error, changeset} = Accounts.create_user(%{})

      assert "can't be blank" in errors_on(changeset).password
    end

    test "requires a password to be 8 or more characters" do
      {:error, changeset} = Accounts.create_user(%{password: "no"})

      assert "should be at least 8 character(s)" in errors_on(changeset).password
    end

    test "requires a password to be less than 72 characters" do
      {:error, changeset} = Accounts.create_user(%{password: String.duplicate("a", 75)})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "returns a user" do
      email = "user#{System.unique_integer()}@example.com"

      {:ok, user} =
        Accounts.create_user(%{
          name: "Foobar",
          email: email,
          password: "copilot123"
        })

      assert user.name == "Foobar"
      assert user.email == email
      assert is_binary(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "create_user_changeset/2" do
    test "returns a changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.create_user_changeset(%User{})
      assert changeset.required == [:password, :email, :name]
    end
  end

  describe "create_user_session_token/1" do
    test "returns a token", %{user: user} do
      {:ok, token} = Accounts.create_user_session_token(user)

      assert is_binary(token)
    end

    test "creates a user token", %{user: user} do
      with {:ok, encoded_token} <- Accounts.create_user_session_token(user),
           {:ok, token} <- UserToken.decode_token(encoded_token) do
        assert user_token = Repo.get_by(UserToken, token: token)
        assert user_token.context == "session"
      end
    end
  end

  describe "find_user_by_session_token/1" do
    setup %{user: user} do
      {:ok, encoded_token} = Accounts.create_user_session_token(user)

      %{user: user, encoded_token: encoded_token}
    end

    test "returns nil with an invalid token" do
      refute Accounts.find_user_by_session_token("no")
    end

    test "returns nil with an expired token", %{encoded_token: encoded_token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      refute Accounts.find_user_by_session_token(encoded_token)
    end

    test "returns a user", %{user: user, encoded_token: encoded_token} do
      assert %User{} = returned_user = Accounts.find_user_by_session_token(encoded_token)

      assert returned_user.id == user.id
    end
  end

  describe "destroy_session_token/1" do
    setup %{user: user} do
      {:ok, encoded_token} = Accounts.create_user_session_token(user)

      %{user: user, encoded_token: encoded_token}
    end

    test "deletes the session token", %{encoded_token: encoded_token} do
      assert Accounts.destroy_session_token(encoded_token) == :ok
      refute Accounts.find_user_by_session_token(encoded_token)
    end
  end

  describe "create_user_confirmation_token/1" do
    setup do
      %{unconfirmed_user: insert(:user, %{confirmed_at: nil})}
    end

    test "returns an error if the user is already confirmed", %{user: user} do
      assert user.confirmed_at
      assert {:error, :already_confirmed} = Accounts.create_user_confirmation_token(user)
    end

    test "returns a token", %{unconfirmed_user: user} do
      {:ok, token} = Accounts.create_user_confirmation_token(user)

      assert is_binary(token)
    end

    test "creates a user token", %{unconfirmed_user: user} do
      {:ok, encoded_token} = Accounts.create_user_confirmation_token(user)

      token =
        with {:ok, decoded_token} <- UserToken.decode_token(encoded_token) do
          :crypto.hash(:blake2b, decoded_token)
        end

      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "confirm"
    end
  end

  describe "confirm_user/1" do
    setup do
      unconfirmed_user = insert(:user, %{confirmed_at: nil})
      {:ok, encoded_token} = Accounts.create_user_confirmation_token(unconfirmed_user)

      %{unconfirmed_user: unconfirmed_user, encoded_token: encoded_token}
    end

    test "returns an error with a malformed token" do
      assert :error = Accounts.confirm_user("no")
    end

    test "returns an error with an expired token", %{encoded_token: encoded_token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.confirm_user(encoded_token) == :error
    end

    test "sets the user's confirmation timestamp", %{
      unconfirmed_user: user,
      encoded_token: encoded_token
    } do
      {:ok, %User{} = confirmed_user} = Accounts.confirm_user(encoded_token)

      assert confirmed_user.id == user.id
      assert confirmed_user.confirmed_at
    end

    test "deletes the token", %{encoded_token: encoded_token} do
      with {:ok, _} <- Accounts.confirm_user(encoded_token),
           {:ok, token} <- UserToken.decode_token(encoded_token) do
        refute Repo.get_by(UserToken, token: token)
      end
    end
  end

  describe "deliver_user_confirmation_instructions/2" do
    setup do
      unconfirmed_user = insert(:user, %{confirmed_at: nil})

      %{unconfirmed_user: unconfirmed_user}
    end

    test "returns an email struct", %{unconfirmed_user: user} do
      assert {:ok, %Swoosh.Email{}} =
               Accounts.deliver_user_confirmation_instructions(user, fn url -> url end)
    end

    test "returns an email with the link in the body", %{unconfirmed_user: user} do
      with {:ok, %Swoosh.Email{} = email} <-
             Accounts.deliver_user_confirmation_instructions(user, fn url ->
               "[TOKEN]#{url}[TOKEN]"
             end),
           [_, encoded_token | _] <- String.split(email.text_body, "[TOKEN]"),
           {:ok, token} <- UserToken.decode_token(encoded_token),
           hashed_token <-
             UserToken.hash_token(token) do
        assert user_token = Repo.get_by(UserToken, token: hashed_token)
        assert user_token.user_id == user.id
        assert user_token.sent_to == user.email
        assert user_token.context == "confirm"
      end
    end
  end

  describe "create_user_reset_password_token/1" do
    test "returns a token", %{user: user} do
      {:ok, token} = Accounts.create_user_reset_password_token(user)

      assert is_binary(token)
    end

    test "creates a user token", %{user: user} do
      {:ok, encoded_token} = Accounts.create_user_reset_password_token(user)

      token =
        with {:ok, decoded_token} <- UserToken.decode_token(encoded_token) do
          :crypto.hash(:blake2b, decoded_token)
        end

      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "reset_password"
    end
  end

  describe "deliver_user_reset_password_instructions/2" do
    test "returns an email struct", %{user: user} do
      assert {:ok, %Swoosh.Email{}} =
               Accounts.deliver_user_reset_password_instructions(user, fn url -> url end)
    end

    test "returns an email with the link in the body", %{user: user} do
      with {:ok, %Swoosh.Email{} = email} <-
             Accounts.deliver_user_reset_password_instructions(user, fn url ->
               "[TOKEN]#{url}[TOKEN]"
             end),
           [_, encoded_token | _] <- String.split(email.text_body, "[TOKEN]"),
           {:ok, token} <- UserToken.decode_token(encoded_token),
           hashed_token <-
             UserToken.hash_token(token) do
        assert user_token = Repo.get_by(UserToken, token: hashed_token)
        assert user_token.user_id == user.id
        assert user_token.sent_to == user.email
        assert user_token.context == "reset_password"
      end
    end
  end

  describe "reset_user_password/2" do
    test "validates the password", %{user: user} do
      {:error, changeset} =
        Accounts.reset_user_password(user, %{
          password: "no",
          password_confirmation: "wrong"
        })

      assert %{
               password: ["should be at least 8 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, updated_user} =
        Accounts.reset_user_password(user, %{
          password: "thisisvalid",
          password_confirmation: "thisisvalid"
        })

      assert is_nil(updated_user.password)
      assert Accounts.find_user_by_email_and_password(user.email, "thisisvalid")
    end

    test "deletes all tokens for the user", %{user: user} do
      _ = Accounts.create_user_session_token(user)

      {:ok, _} =
        Accounts.reset_user_password(user, %{
          password: "thisisvalid",
          password_confirmation: "thisisvalid"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "find_user_by_reset_password_token/1" do
    setup %{user: user} do
      encoded_token =
        extract_user_token(fn url ->
          Accounts.deliver_user_reset_password_instructions(user, url)
        end)

      %{user: user, encoded_token: encoded_token}
    end

    test "returns a user with a valid token", %{user: %{id: id}, encoded_token: encoded_token} do
      assert %User{id: ^id} = Accounts.find_user_by_reset_password_token(encoded_token)
      assert Repo.get_by(UserToken, user_id: id)
    end

    test "does not return user with invalid token", %{user: user} do
      refute Accounts.find_user_by_reset_password_token("no")
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not return user if token expired", %{user: user, encoded_token: encoded_token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.find_user_by_reset_password_token(encoded_token)
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "deliver_user_update_email_instructions/2" do
    test "sends token through email", %{user: user} do
      encoded_token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = UserToken.decode_token(encoded_token)
      assert user_token = Repo.get_by(UserToken, token: UserToken.hash_token(token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup %{user: user} do
      email = build(:user).email

      encoded_token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{encoded_token: encoded_token, email: email}
    end

    test "updates the email with a valid token", %{
      user: user,
      encoded_token: encoded_token,
      email: email
    } do
      assert Accounts.update_user_email(user, encoded_token) == :ok
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      assert changed_user.confirmed_at
      assert changed_user.confirmed_at != user.confirmed_at
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with an invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if the user email changed", %{
      user: user,
      encoded_token: encoded_token
    } do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, encoded_token) ==
               :error

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, encoded_token: encoded_token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      assert Accounts.update_user_email(user, encoded_token) == :error
      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "update_user_password_changeset/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.update_user_password_changeset(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.update_user_password_changeset(%User{}, %{
          "password" => "new valid password"
        })

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/3" do
    test "validates the user's password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "copilot123", %{
          password: "no",
          password_confirmation: "way"
        })

      assert %{
               password: ["should be at least 8 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, "copilot123", %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "validates current password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, "invalid", %{password: "copilot123"})

      assert %{current_password: ["is not correct"]} = errors_on(changeset)
    end

    test "updates the password", %{user: user} do
      {:ok, user} =
        Accounts.update_user_password(user, "copilot123", %{
          password: "new valid password"
        })

      assert is_nil(user.password)
      assert Accounts.find_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.create_user_session_token(user)

      {:ok, _} =
        Accounts.update_user_password(user, "copilot123", %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "update_user_email_changeset/2" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.update_user_email_changeset(%User{})
      assert changeset.required == [:email]
    end
  end
end

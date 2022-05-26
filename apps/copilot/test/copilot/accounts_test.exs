defmodule Copilot.AccountsTest do
  @moduledoc false

  use Copilot.DataCase, async: true

  alias Copilot.Accounts
  alias Copilot.Accounts.{User, UserToken}

  setup do
    %{user: insert(:user)}
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
        with {:ok, decoded_token} <- Base.url_decode64(encoded_token, padding: false) do
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
      {:ok, token} = Accounts.create_user_confirmation_token(unconfirmed_user)

      %{unconfirmed_user: unconfirmed_user, token: Base.decode64(token, padding: false)}
    end

    test "sets the user's confirmation timestamp", %{unconfirmed_user: user, token: token} do
      {:ok, %User{}} = confirmed_user = Accounts.confirm_user(user)

      assert confirmed_user.id == user.id
      assert confirmed_user.confirmed_at
    end
  end
end

defmodule Copilot.Accounts do
  @moduledoc false

  alias Copilot.Accounts.{User, UserToken}
  alias Copilot.Repo

  @doc """
  Find a user by their email
  """
  @spec find_user_by_email(String.t()) :: User.t() | nil
  def find_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Creates a new, unconfirmed user
  """
  @spec create_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def create_user(attrs) do
    %User{}
    |> User.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Creates a hashed token for use in a confirmation email. Just returns the token
  """
  @spec create_user_confirmation_token(User.t()) ::
          {:error, :already_confirmed} | {:error, Ecto.Changeset.t()} | {:ok, binary()}
  def create_user_confirmation_token(user) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")

      case Repo.insert(user_token) do
        {:ok, _} -> {:ok, encoded_token}
        {:error, %Ecto.Changeset{} = changeset} -> {:error, changeset}
      end
    end
  end

  @doc """
  Confirms a user based on an unhashed token
  """
  @spec confirm_user(String.t()) :: {:ok, User.t()} | :error
  def confirm_user(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, %{user: user}} <- Repo.transaction(confirm_user_transaction(user)) do
      {:ok, user}
    else
      _ -> :error
    end
  end

  @spec confirm_user_transaction(User.t()) :: Ecto.Multi.t()
  defp confirm_user_transaction(user) do
    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, User.confirm_changeset(user))
    |> Ecto.Multi.delete_all(:tokens, UserToken.find_by_user_and_context_query(user, ["confirm"]))
  end
end

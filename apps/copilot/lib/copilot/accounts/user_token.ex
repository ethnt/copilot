defmodule Copilot.Accounts.UserToken do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Query

  alias Copilot.Accounts.{User, UserToken}

  @hash_algorithm :blake2b
  @rand_size 32

  @reset_password_validity_in_days 1
  @confirm_validity_in_days 7
  @session_validity_in_days 60

  @type t :: %__MODULE__{
          id: integer(),
          token: binary(),
          context: String.t() | nil,
          sent_to: String.t() | nil,
          user_id: integer(),
          user: User.t(),
          inserted_at: NaiveDateTime.t()
        }

  schema "user_tokens" do
    field :token, :binary
    field :context, :string
    field :sent_to, :string

    belongs_to :user, User

    timestamps(updated_at: false)
  end

  @doc """
  Generate a token that will be stored in a signed place (session or cookie). No need to hash them in this case
  """
  @spec build_session_token(User.t()) :: %UserToken{}
  def build_session_token(user) do
    token = :crypto.strong_rand_bytes(@rand_size)

    %UserToken{token: token, context: "session", user_id: user.id}
  end

  @doc """
  Generate a token that will be stored in a unsigned place (email). If anyone gets this token, they won't be able to use
  it to gain access. The hashed version is in the database and the unhashed version is sent to the user. When the user
  confirms, they will send the unhashed version -- we will hash their input and match against ours in the database
  """
  @spec build_email_token(User.t(), String.t()) :: {binary, %UserToken{}}
  def build_email_token(%User{email: email} = user, context) do
    build_hashed_token(user, context, email)
  end

  # TODO: Change to return non-encoded tokens (do the url encode elsehwere)
  @spec build_hashed_token(User.t(), String.t(), String.t()) :: {binary, %UserToken{}}
  defp build_hashed_token(user, context, sent_to) do
    token = :crypto.strong_rand_bytes(@rand_size)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    {Base.url_encode64(token, padding: false),
     %UserToken{
       token: hashed_token,
       context: context,
       sent_to: sent_to,
       user_id: user.id
     }}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query. The query returns the user found by the token,
  if any. The token is valid if it matches the value in the database and it has not expired
  """
  @spec verify_session_token_query(binary()) :: {:ok, Ecto.Query.t()}
  def verify_session_token_query(token) do
    query =
      from token in find_by_token_and_context_query(token, "session"),
        join: user in assoc(token, :user),
        where: token.inserted_at > ago(@session_validity_in_days, "day"),
        select: user

    {:ok, query}
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query. The query returns the user found by the token,
  if any. The token is valid if it matches the value in the database and it has not expired
  """
  # TODO: Change to not use url_decode (do that elsewhere)
  @spec verify_email_token_query(binary, String.t()) :: {:ok, Ecto.Query.t()} | :error
  def verify_email_token_query(token, context) do
    case Base.url_decode64(token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)
        days = days_for_context(context)

        query =
          from token in find_by_token_and_context_query(hashed_token, context),
            join: user in assoc(token, :user),
            where: token.inserted_at > ago(^days, "day") and token.sent_to == user.email,
            select: user

        {:ok, query}

      :error ->
        :error
    end
  end

  @spec days_for_context(String.t()) :: integer()
  defp days_for_context("confirm"), do: @confirm_validity_in_days
  defp days_for_context("reset_password"), do: @reset_password_validity_in_days

  @doc """
  Returns a query to find a token based on the given token and context
  """
  @spec find_by_token_and_context_query(binary(), String.t()) :: Ecto.Query.t()
  def find_by_token_and_context_query(token, context) do
    from UserToken, where: [token: ^token, context: ^context]
  end

  @doc """
  Returns a query to find a token based on a given user and a list of contexts (or `:all`)
  """
  @spec find_by_user_and_context_query(User.t(), :all | nonempty_maybe_improper_list) :: Ecto.Query.t()
  def find_by_user_and_context_query(user, :all) do
    from t in UserToken, where: t.user_id == ^user.id
  end

  def find_by_user_and_context_query(user, [_ | _] = contexts) do
    from t in UserToken, where: t.user_id == ^user.id and t.context in ^contexts
  end

  @spec encode_token(binary) :: String.t()
  def encode_token(token) when is_binary(token) do
    Base.url_encode64(token, padding: false)
  end

  @spec decode_token(String.t()) :: {:ok, binary()} | :error
  def decode_token(token) do
    Base.url_decode64(token, padding: false)
  end
end

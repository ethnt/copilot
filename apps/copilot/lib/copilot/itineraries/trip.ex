defmodule Copilot.Itineraries.Trip do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Copilot.Accounts.User
  alias Copilot.Itineraries.Trip

  @type t :: %__MODULE__{
          id: integer(),
          name: String.t(),
          description: String.t() | nil,
          start_date: Date.t(),
          end_date: Date.t(),
          user_id: integer(),
          user: User.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "trips" do
    field :name, :string
    field :description, :string
    field :start_date, :date
    field :end_date, :date

    belongs_to :user, User

    timestamps()
  end

  @spec create_changeset(%Trip{}, map(), User.t()) :: Ecto.Changeset.t()
  def create_changeset(trip, attrs, user) do
    trip
    |> cast(attrs, [:name, :description, :start_date, :end_date])
    |> validate_required([:name, :description, :start_date, :end_date])
    |> validate_date_order()
    |> put_assoc(:user, user)
  end

  @spec update_changeset(Trip.t(), map()) :: Ecto.Changeset.t()
  def update_changeset(trip, attrs) do
    trip
    |> cast(attrs, [:name, :description, :start_date, :end_date])
    |> validate_required([:name, :description, :start_date, :end_date])
    |> validate_date_order()
  end

  @spec validate_date_order(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp validate_date_order(changeset) do
    with %Date{} = start_date <- get_field(changeset, :start_date),
         %Date{} = end_date <- get_field(changeset, :end_date) do
      if Date.compare(start_date, end_date) == :gt do
        add_error(changeset, :end_date, "must be after the start date")
      else
        changeset
      end
    else
      _ -> changeset
    end
  end
end

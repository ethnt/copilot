defmodule Copilot.Itineraries.Trip do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  import Copilot.Helpers

  alias Copilot.Accounts.User
  alias Copilot.Itineraries.{Plan, Trip}

  @type t :: %__MODULE__{
          id: integer(),
          name: String.t(),
          description: String.t() | nil,
          start_date: Date.t(),
          end_date: Date.t(),
          plans: [Plan.t()],
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

    has_many :plans, Plan

    timestamps()
  end

  @spec create_changeset(%Trip{}, map(), User.t()) :: Ecto.Changeset.t()
  def create_changeset(trip, attrs, user) do
    trip
    |> cast(attrs, [:name, :description, :start_date, :end_date])
    |> validate_required([:name, :start_date, :end_date])
    |> validate_date_order()
    |> put_assoc(:user, user)
  end

  @spec update_changeset(Trip.t(), map()) :: Ecto.Changeset.t()
  def update_changeset(trip, attrs) do
    trip
    |> cast(attrs, [:name, :description, :start_date, :end_date])
    |> validate_required([:name, :start_date, :end_date])
    |> validate_date_order()
  end
end

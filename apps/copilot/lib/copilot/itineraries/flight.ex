defmodule Copilot.Itineraries.Flight do
  @moduledoc false

  use Ecto.Schema

  alias Copilot.Itineraries.{Flight, FlightSegment, Trip}

  import Ecto.Changeset

  @type t :: %__MODULE__{
          id: integer(),
          canonical_start: DateTime.t(),
          canonical_end: DateTime.t(),
          booking_reference: String.t(),
          trip_id: integer(),
          trip: Trip.t() | nil,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "flights" do
    field :canonical_start, :utc_datetime
    field :canonical_end, :utc_datetime
    field :booking_reference, :string

    belongs_to :trip, Trip
    embeds_many :flight_segments, FlightSegment

    timestamps()
  end

  @spec create_changeset(%Flight{}, map(), Trip.t()) :: Ecto.Changeset.t()
  def create_changeset(flight, attrs, trip) do
    flight
    |> cast(attrs, [:canonical_start, :canonical_end, :booking_reference])
    |> validate_required([:canonical_start, :canonical_end])
    |> cast_embed(:flight_segments, required: true)
    |> put_assoc(:trip, trip)
  end
end

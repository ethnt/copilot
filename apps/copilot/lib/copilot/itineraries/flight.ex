defmodule Copilot.Itineraries.Flight do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Copilot.Itineraries.{Flight, FlightSegment, Plan}

  @behaviour Plan.Kind

  @type t :: %__MODULE__{
          booking_reference: String.t(),
          flight_segments: [FlightSegment.t()]
        }

  embedded_schema do
    field :booking_reference, :string

    embeds_many :flight_segments, FlightSegment
  end

  @impl Plan.Kind
  @spec changeset(%Flight{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(flight, attrs) do
    flight
    |> cast(attrs, [:booking_reference])
    |> cast_embed(:flight_segments, required: true)
    |> ensure_flight_segment_order()
  end

  @doc """
  Returns the canonical datetimes for this flight
  """
  @impl Plan.Kind
  @spec canonical_datetimes(Flight.t()) :: Plan.Kind.date_range()
  def canonical_datetimes(%Flight{flight_segments: flight_segments}) do
    flight_segments = Enum.sort_by(flight_segments, & &1.departure_time, DateTime)

    start_time = flight_segments |> List.first() |> Map.get(:departure_time)
    end_time = flight_segments |> List.last() |> Map.get(:arrival_time)

    {start_time, end_time}
  end

  @spec ensure_flight_segment_order(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  defp ensure_flight_segment_order(changeset) do
    if changeset.valid? do
      flight_segments =
        changeset
        |> get_field(:flight_segments)
        |> sort_flight_segments()

      put_change(changeset, :flight_segments, flight_segments)
    else
      changeset
    end
  end

  @spec sort_flight_segments([FlightSegment.t()]) :: [FlightSegment.t()]
  defp sort_flight_segments(flight_segments) do
    Enum.sort_by(flight_segments, & &1.departure_time, DateTime)
  end
end

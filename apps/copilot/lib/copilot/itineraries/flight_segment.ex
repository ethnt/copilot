defmodule Copilot.Itineraries.FlightSegment do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  import Copilot.Helpers

  alias Copilot.Itineraries.FlightSegment

  @type t :: %__MODULE__{
          airline: String.t(),
          number: String.t(),
          origin: String.t(),
          departure_time: DateTime.t(),
          destination: String.t(),
          arrival_time: DateTime.t()
        }

  embedded_schema do
    field :airline, :string
    field :number, :string
    field :origin, :string
    field :departure_time, :utc_datetime
    field :destination, :string
    field :arrival_time, :utc_datetime
  end

  @spec changeset(%FlightSegment{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(flight_segment, attrs) do
    flight_segment
    |> cast(attrs, [:airline, :number, :origin, :departure_time, :destination, :arrival_time])
    |> validate_required([
      :airline,
      :number,
      :origin,
      :departure_time,
      :destination,
      :arrival_time
    ])
    |> validate_time_order(:departure_time, :arrival_time, "must be after the departure time")
  end
end

defmodule Copilot.Itineraries.FlightSegment do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Copilot.Itineraries.FlightSegment

  embedded_schema do
    field :airline, :string
    field :number, :string
    field :origin, :string
    field :departure_time, :utc_datetime
    field :destination, :string
    field :arrival_time, :utc_datetime

    timestamps()
  end

  @spec changeset(%FlightSegment{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(flight_segment, attrs) do
    flight_segment
    |> cast(attrs, [:airline, :number, :origin, :departure_time, :destination, :arrival_time])
  end
end

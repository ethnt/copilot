defmodule Copilot.Itineraries.Plan do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query
  import PolymorphicEmbed, only: [cast_polymorphic_embed: 3]

  alias Copilot.Itineraries.{Activity, Flight, Plan, Trip}

  @type t :: %__MODULE__{
          id: integer(),
          canonical_start: DateTime.t(),
          canonical_end: DateTime.t(),
          attributes: Plan.Kind,
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t(),
          trip_id: integer(),
          trip: Trip.t() | nil
        }

  @type canonical_datetimes :: {canonical_start :: DateTime.t(), canonical_end :: DateTime.t()}

  schema "plans" do
    field :canonical_start, :utc_datetime
    field :canonical_end, :utc_datetime

    field :attributes, PolymorphicEmbed,
      types: [
        flight: Flight,
        activity: Activity
      ],
      on_type_not_found: :raise,
      on_replace: :update

    timestamps()

    belongs_to :trip, Trip
  end

  @doc """
  Creation changeset for plans with explicit type added to the attributes
  """
  @spec create_changeset(%Plan{}, map(), String.t(), Trip.t()) :: Ecto.Changeset.t()
  def create_changeset(plan, attrs, type, trip) do
    attrs = finalize_attrs(attrs, type)
    create_changeset(plan, attrs, trip)
  end

  @doc """
  Creation changeset for plans with the type already in the attributes
  """
  @spec create_changeset(%Plan{}, map(), Trip.t()) :: Ecto.Changeset.t()
  def create_changeset(plan, attrs, trip) do
    plan
    |> cast(attrs, [])
    |> cast_polymorphic_embed(:attributes, required: true)
    |> Plan.Kind.derive_canonical_times()
    |> put_assoc(:trip, trip)
  end

  @doc """
  Query to find plans by trip and plan type
  """
  @spec find_by_trip_and_type_query(Copilot.Itineraries.Trip.t(), String.t()) :: Ecto.Query.t()
  def find_by_trip_and_type_query(%Trip{id: trip_id}, type) do
    from p in Plan,
      where: p.trip_id == ^trip_id,
      where: p.attributes["__type__"] == ^type
  end

  # Adds the type attribute if it's not already there
  @spec finalize_attrs(map(), String.t()) :: map()
  defp finalize_attrs(attrs, type) do
    Map.merge(
      attrs,
      %{attributes: %{__type__: type}},
      fn _, a, b -> Map.merge(a, b) end
    )
  end
end

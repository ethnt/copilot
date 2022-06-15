defmodule Copilot.Itineraries.Activity do
  @moduledoc false

  @behaviour Copilot.Itineraries.Plan.Kind

  use Ecto.Schema

  import Ecto.Changeset

  import Copilot.Helpers

  alias Copilot.Itineraries.{Activity, Plan}

  @type t :: %__MODULE__{
          name: String.t(),
          start_time: DateTime.t(),
          end_time: DateTime.t()
        }

  embedded_schema do
    field :name, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
  end

  @spec changeset(%Activity{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:name, :start_time, :end_time])
    |> validate_required([:name, :start_time, :end_time])
    |> validate_time_order()
  end

  @doc """
  Returns the canonical datetimes for this activity
  """
  @impl Plan.Kind
  @spec canonical_datetimes(Activity.t()) :: Plan.Kind.date_range()
  def canonical_datetimes(%Activity{start_time: start_time, end_time: end_time}) do
    {start_time, end_time}
  end
end

defmodule Copilot.Itineraries.Activity do
  @moduledoc false

  use Ecto.Schema

  import Copilot.Helpers
  import Ecto.Changeset

  alias Copilot.Itineraries.{Activity, Plan}

  @behaviour Plan.Kind

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

  @impl Plan.Kind
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

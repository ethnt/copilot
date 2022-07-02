defmodule Copilot.Itineraries.Lodging do
  @moduledoc false

  use Ecto.Schema

  import Copilot.Helpers
  import Ecto.Changeset

  alias Copilot.Itineraries.{Lodging, Plan}

  @behaviour Plan.Kind

  @type t :: %__MODULE__{
          name: String.t(),
          address: map(),
          check_in: DateTime.t(),
          check_out: DateTime.t()
        }

  embedded_schema do
    field :name, :string
    field :address, :map
    field :check_in, :utc_datetime
    field :check_out, :utc_datetime
  end

  @impl Plan.Kind
  @spec changeset(%Lodging{} | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()
  def changeset(lodging, attrs) do
    lodging
    |> cast(attrs, [:name, :address, :check_in, :check_out])
    |> validate_required([:name, :address, :check_in, :check_out])
    |> validate_time_order(:check_in, :check_out, "must be after the check in time")
  end

  @impl Plan.Kind
  @spec canonical_datetimes(Lodging.t()) :: Plan.Kind.date_range()
  def canonical_datetimes(%Lodging{check_in: check_in, check_out: check_out}) do
    {check_in, check_out}
  end
end

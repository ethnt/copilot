defmodule Copilot.Itineraries.Plan.Kind do
  @moduledoc false

  import Ecto.Changeset, only: [get_change: 2, change: 2]

  @type date_range :: {canonical_start :: DateTime.t(), canonical_end :: DateTime.t()}

  @callback changeset(Ecto.Schema.t() | Ecto.Changeset.t(), map()) :: Ecto.Changeset.t()

  @callback canonical_datetimes(Ecto.Schema.t()) :: date_range()

  @doc """
  Takes a plan changeset, grabs the inner embedded plan, derives the canonical start and end times, and applies that to
  the plan changeset
  """
  @spec derive_canonical_times(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def derive_canonical_times(changeset) do
    case get_change(changeset, :attributes) do
      %Ecto.Changeset{} ->
        changeset

      struct ->
        {canonical_start, canonical_end} = struct.__struct__.canonical_datetimes(struct)
        change(changeset, %{canonical_start: canonical_start, canonical_end: canonical_end})
    end
  end
end

defmodule Copilot.Itineraries.Plan.Kind do
  @moduledoc false

  import Ecto.Changeset, only: [get_change: 2, change: 2]

  @type date_range :: {canonical_start :: DateTime.t(), canonical_end :: DateTime.t()}

  @callback canonical_datetimes(Ecto.Schema.t()) :: date_range()

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

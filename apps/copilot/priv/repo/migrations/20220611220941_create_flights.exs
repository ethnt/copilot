defmodule Copilot.Repo.Migrations.CreateFlights do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:flights, options: "INHERITS (plans)") do
      add :booking_reference, :string
      add :flight_segments, {:array, :map}, default: []
    end
  end
end

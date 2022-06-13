defmodule Copilot.Repo.Migrations.CreatePlans do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:plans) do
      add :trip_id, references(:trips, on_delete: :delete_all), null: false
      add :canonical_start, :utc_datetime
      add :canonical_end, :utc_datetime

      timestamps()
    end

    create index(:plans, [:trip_id])
  end
end

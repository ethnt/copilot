defmodule Copilot.Repo.Migrations.CreateTrips do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:trips) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :string
      add :start_date, :date, null: false
      add :end_date, :date, null: false

      timestamps()
    end

    create index(:trips, [:user_id])
  end
end

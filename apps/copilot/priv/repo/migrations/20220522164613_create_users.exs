defmodule Copilot.Repo.Migrations.CreateUsers do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add :name, :string, null: false
      add :email, :citext, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end

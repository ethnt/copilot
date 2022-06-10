defmodule Copilot.Itineraries do
  @moduledoc false

  import Ecto.Query

  alias Copilot.Accounts.User
  alias Copilot.Itineraries.Trip
  alias Copilot.Repo

  @doc """
  Find all trips for a user
  """
  @spec find_trips_for_user(User.t()) :: [Trip.t()]
  def find_trips_for_user(user) do
    Repo.all(from t in Trip, where: t.user_id == ^user.id, order_by: t.start_date)
  end

  @doc """
  Create a new trip
  """
  @spec create_trip(map(), User.t()) :: {:ok, Trip.t()} | {:error, Ecto.Changeset.t()}
  def create_trip(attrs, user) do
    %Trip{}
    |> Trip.create_changeset(attrs, user)
    |> Repo.insert()
  end

  @doc """
  Update a trip
  """
  @spec update_trip(Trip.t(), map()) :: {:ok, Trip.t()} | {:error, Ecto.Changeset.t()}
  def update_trip(trip, attrs) do
    trip
    |> Trip.update_changeset(attrs)
    |> Repo.update()
  end

  @spec destroy_trip(Trip.t()) :: {:ok, Trip.t()} | {:error, Ecto.Changeset.t()}
  def destroy_trip(trip) do
    Repo.delete(trip)
  end
end

defmodule Copilot.Itineraries do
  @moduledoc false

  import Ecto.Query

  alias Copilot.Accounts.User
  alias Copilot.Itineraries.{Plan, Trip}
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

  @doc """
  Destroys a trip
  """
  @spec destroy_trip(Trip.t()) :: {:ok, Trip.t()} | {:error, Ecto.Changeset.t()}
  def destroy_trip(trip) do
    Repo.delete(trip)
  end

  @spec find_plans_by_trip_and_type(Trip.t(), String.t()) :: [Plan.t()]
  def find_plans_by_trip_and_type(trip, type) do
    Repo.all(Plan.find_by_trip_and_type_query(trip, type))
  end

  @doc """
  Create a new plan
  """
  @spec create_plan(map(), Trip.t()) :: {:ok, Plan.t()} | {:error, Ecto.Changeset.t()}
  def create_plan(attrs, trip) do
    %Plan{}
    |> Plan.create_changeset(attrs, trip)
    |> Repo.insert()
  end
end

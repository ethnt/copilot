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

  @spec find_trip_by_user_and_id(User.t(), integer()) :: Trip.t() | nil
  def find_trip_by_user_and_id(user, id) do
    Repo.one(from t in Trip, where: t.id == ^id, where: t.user_id == ^user.id)
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
  Returns a changeset for tracking changes to trip creation
  """
  @spec create_trip_changeset(%Trip{}, User.t(), map()) :: Ecto.Changeset.t()
  def create_trip_changeset(%Trip{} = trip, user, attrs \\ %{}) do
    Trip.create_changeset(trip, attrs, user)
  end

  @doc """
  Returns a changeset for tracking changes to trip modification
  """
  @spec update_trip_changeset(Trip.t(), map()) :: Ecto.Changeset.t()
  def update_trip_changeset(trip, attrs \\ %{}) do
    Trip.update_changeset(trip, attrs)
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

  @doc """
  Find plans based on trip and type
  """
  @spec find_plans_by_trip_and_type(Trip.t(), String.t()) :: [Plan.t()]
  def find_plans_by_trip_and_type(trip, type) do
    Repo.all(Plan.find_by_trip_and_type_query(trip, type))
  end

  @doc """
  Create a new plan with just the kind's attributes
  """
  @spec create_plan(map(), String.t(), Trip.t()) :: {:ok, Plan.t()} | {:error, Ecto.Changeset.t()}
  def create_plan(attrs, kind, trip) do
    %Plan{}
    |> Plan.create_changeset(attrs, kind, trip)
    |> Repo.insert()
  end
end

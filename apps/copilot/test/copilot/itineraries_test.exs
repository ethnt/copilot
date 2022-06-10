defmodule Copilot.ItinerariesTest do
  @moduledoc false

  use Copilot.DataCase, async: true

  alias Copilot.Itineraries
  alias Copilot.Repo

  setup do
    %{user: insert(:user)}
  end

  describe "create_trip/2" do
    test "requires a name", %{user: user} do
      {:error, changeset} = Itineraries.create_trip(%{}, user)

      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires a start_date", %{user: user} do
      {:error, changeset} = Itineraries.create_trip(%{}, user)

      assert %{start_date: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires an end_date", %{user: user} do
      {:error, changeset} = Itineraries.create_trip(%{}, user)

      assert %{end_date: ["can't be blank"]} = errors_on(changeset)
    end

    test "requires the end date to be after the start date", %{user: user} do
      {:error, changeset} =
        Itineraries.create_trip(%{start_date: ~D[2020-01-01], end_date: ~D[2019-01-01]}, user)

      assert %{end_date: ["must be after the start date"]} = errors_on(changeset)
    end
  end

  describe "update_trip/2" do
    setup %{user: user} do
      %{trip: insert(:trip, user: user)}
    end

    test "updates the trip", %{trip: trip} do
      {:ok, updated_trip} =
        Itineraries.update_trip(trip, %{name: "Trip to Tokyo", description: "Tokyo!"})

      assert updated_trip.id == trip.id
      assert updated_trip.name == "Trip to Tokyo"
      assert updated_trip.description == "Tokyo!"
    end
  end

  describe "destroy_trip/1" do
    setup %{user: user} do
      %{trip: insert(:trip, user: user)}
    end

    test "destroys the trip", %{trip: trip} do
      {:ok, _} = Itineraries.destroy_trip(trip)

      refute Repo.get(Itineraries.Trip, trip.id)
    end
  end

  describe "find_trips_for_user/1" do
    setup %{user: user} do
      %{trips: insert_list(3, :trip, user: user)}
    end

    test "returns all trips", %{user: user, trips: trips} do
      result = Itineraries.find_trips_for_user(user)

      assert matching_ids(result, trips)
    end
  end
end

defmodule Copilot.ItinerariesTest do
  @moduledoc false

  use Copilot.DataCase, async: true

  alias Copilot.Itineraries
  alias Copilot.Repo

  setup do
    trip = insert(:trip)

    %{trip: trip, user: trip.user}
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
    setup do
      other_user = insert(:user)

      %{trips: insert_list(3, :trip, user: other_user), other_user: other_user}
    end

    test "returns all trips", %{other_user: user, trips: trips} do
      result = Itineraries.find_trips_for_user(user)

      assert matching_ids(result, trips)
    end
  end

  describe "create_plan/3 with activity" do
    test "requires a name", %{trip: trip} do
      {:error, changeset} = Itineraries.create_plan(%{}, "activity", trip)

      assert "can't be blank" in errors_on(changeset).attributes.name
    end

    test "requires a start time", %{trip: trip} do
      {:error, changeset} = Itineraries.create_plan(%{}, "activity", trip)

      assert "can't be blank" in errors_on(changeset).attributes.start_time
    end

    test "requires an end time", %{trip: trip} do
      {:error, changeset} = Itineraries.create_plan(%{}, "activity", trip)

      assert "can't be blank" in errors_on(changeset).attributes.end_time
    end

    test "requires the end time to be after the start time", %{trip: trip} do
      {:error, changeset} =
        Itineraries.create_plan(
          %{
            name: "Hiking",
            start_time: ~U[2022-01-01 10:00:00Z],
            end_time: ~U[2022-01-01 09:00:00Z]
          },
          "activity",
          trip
        )

      assert "must be after the start time" in errors_on(changeset).attributes.end_time
    end

    test "returns a plan with valid attributes", %{trip: trip} do
      {:ok, plan} = Itineraries.create_plan(params_for(:activity), "activity", trip)

      assert plan.trip_id == trip.id
      assert %Copilot.Itineraries.Activity{} = activity = plan.attributes
      assert activity.name == "Hiking"
    end

    test "properly derives canonical date and time", %{trip: trip} do
      {:ok, plan} = Itineraries.create_plan(params_for(:activity), "activity", trip)

      assert %Copilot.Itineraries.Activity{} = activity = plan.attributes
      assert activity.start_time == plan.canonical_start
      assert activity.end_time == plan.canonical_end
    end
  end

  describe "create_plan/3 with flight" do
    test "requires flight segments", %{trip: trip} do
      {:error, changeset} = Itineraries.create_plan(%{flight_segments: []}, "flight", trip)

      assert "can't be blank" in errors_on(changeset).attributes.flight_segments
    end

    test "returns a plan with valid attributes", %{trip: trip} do
      {:ok, plan} = Itineraries.create_plan(params_for(:flight), "flight", trip)

      assert plan.trip_id == trip.id
      assert %Copilot.Itineraries.Flight{} = flight = plan.attributes
      assert flight.booking_reference == "ABCDE"
    end

    test "sorts the flight segments in time order", %{trip: trip} do
      {:ok, plan} =
        Itineraries.create_plan(
          %{
            flight_segments: [
              params_for(:flight_segment,
                airline: "middle",
                departure_time: ~U[2022-01-02 20:00:00Z],
                arrival_time: ~U[2022-01-02 21:00:00Z]
              ),
              params_for(:flight_segment,
                airline: "last",
                departure_time: ~U[2022-01-03 20:00:00Z],
                arrival_time: ~U[2022-01-03 21:00:00Z]
              ),
              params_for(:flight_segment,
                airline: "first",
                departure_time: ~U[2022-01-01 20:00:00Z],
                arrival_time: ~U[2022-01-01 21:00:00Z]
              )
            ]
          },
          "flight",
          trip
        )

      assert %Copilot.Itineraries.Flight{} = flight = plan.attributes

      assert Enum.map(flight.flight_segments, fn fs -> fs.airline end) == [
               "first",
               "middle",
               "last"
             ]
    end

    test "ensures no flight segments have incorrect time ordering", %{trip: trip} do
      {:error, changeset} =
        Itineraries.create_plan(
          %{
            flight_segments: [
              params_for(:flight_segment,
                airline: "middle",
                departure_time: ~U[2022-01-02 20:00:00Z],
                arrival_time: ~U[2022-01-01 21:00:00Z]
              )
            ]
          },
          "flight",
          trip
        )

      assert %{arrival_time: ["must be after the departure time"]} in errors_on(changeset).attributes.flight_segments
    end

    test "properly derives canonical date and time", %{trip: trip} do
      {:ok, plan} = Itineraries.create_plan(params_for(:flight), "flight", trip)

      assert %Copilot.Itineraries.Flight{} = flight = plan.attributes

      assert plan.canonical_start ==
               flight.flight_segments |> List.first() |> Map.get(:departure_time)

      assert plan.canonical_end == flight.flight_segments |> List.last() |> Map.get(:arrival_time)
    end
  end

  describe "create_plan/3 with lodging" do
    test "requires a name", %{trip: trip} do
      {:error, changeset} = Itineraries.create_plan(%{}, "lodging", trip)

      assert "can't be blank" in errors_on(changeset).attributes.name
    end

    test "requires an address", %{trip: trip} do
      {:error, changeset} = Itineraries.create_plan(%{}, "lodging", trip)

      assert "can't be blank" in errors_on(changeset).attributes.address
    end

    test "requires a check in", %{trip: trip} do
      {:error, changeset} = Itineraries.create_plan(%{}, "lodging", trip)

      assert "can't be blank" in errors_on(changeset).attributes.check_in
    end

    test "requires a check out", %{trip: trip} do
      {:error, changeset} = Itineraries.create_plan(%{}, "lodging", trip)

      assert "can't be blank" in errors_on(changeset).attributes.check_out
    end

    test "requires the check out time to be after the check in time", %{trip: trip} do
      {:error, changeset} =
        Itineraries.create_plan(
          %{
            name: "Overlook Hotel",
            check_in: ~U[2022-01-01 10:00:00Z],
            check_out: ~U[2022-01-01 09:00:00Z]
          },
          "lodging",
          trip
        )

      assert "must be after the check in time" in errors_on(changeset).attributes.check_out
    end
  end
end

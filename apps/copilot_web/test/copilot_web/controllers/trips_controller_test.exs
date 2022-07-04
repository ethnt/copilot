defmodule CopilotWeb.TripsControllerTest do
  @moduledoc false

  use CopilotWeb.ConnCase, async: true

  setup :register_and_login_user!

  setup %{user: user} do
    trips = insert_list(3, :trip, user: user)
    trip = List.first(trips)

    %{trips: trips, trip: trip, user: trip.user}
  end

  describe "GET /trips" do
    test "renders a list of trips", %{conn: conn, trips: trips} do
      conn = get(conn, Routes.trips_path(conn, :index))
      response = html_response(conn, 200)

      for trip <- trips do
        assert response =~ trip.name
      end
    end
  end

  describe "GET /trips/:id" do
    test "renders information about a single trip", %{conn: conn, trip: trip} do
      conn = get(conn, Routes.trips_path(conn, :show, trip.id))

      assert html_response(conn, 200) =~ trip.name
    end
  end

  describe "GET /trips/new" do
    test "returns a page", %{conn: conn} do
      conn = get(conn, Routes.trips_path(conn, :new))

      assert html_response(conn, 200)
    end
  end

  describe "POST /trips" do
    @tag :capture_log
    test "creates a trip and redirects to the trip", %{conn: conn} do
      conn =
        post(conn, Routes.trips_path(conn, :create), %{
          "trip" => %{
            "name" => "Trip to Copenhagen",
            "start_date" => ~D[2022-07-15],
            "end_date" => ~D[2022-07-21]
          }
        })

      assert redirected_to(conn) =~ ~r/\/trips\/[0-9]+/
    end

    test "renders error for invalid data", %{conn: conn} do
      conn = post(conn, Routes.trips_path(conn, :create), %{"trip" => %{"name" => "No Dates"}})

      assert conn.assigns[:changeset]
      assert html_response(conn, 200)
    end
  end

  describe "GET /trips/:id/edit" do
    test "renders trip update page", %{conn: conn, trip: trip} do
      conn = get(conn, Routes.trips_path(conn, :edit, trip.id))
      response = html_response(conn, 200)

      assert response =~ trip.name
      assert response =~ "Save"
    end
  end

  describe "PATCH /trips/:id" do
    @tag :capture_log
    test "updates the trip and redirects back to show page", %{conn: conn, trip: trip} do
      conn =
        patch(conn, Routes.trips_path(conn, :update, trip.id), %{
          "trip" => %{
            "name" => "Trip to Denmark",
            "start_date" => ~D[2022-07-15],
            "end_date" => ~D[2022-07-21]
          }
        })

      assert redirected_to(conn) == "/trips/#{trip.id}"
    end

    test "renders error for invalid data", %{conn: conn, trip: trip} do
      conn =
        patch(conn, Routes.trips_path(conn, :update, trip.id), %{
          "trip" => %{"start_date" => ~D[2022-07-21], "end_date" => ~D[2022-07-15]}
        })

      assert conn.assigns[:changeset]
      assert html_response(conn, 200)
    end
  end

  describe "DELETE /trips/:id" do
    test "deletes the trip and redirects to trip index", %{conn: conn, trip: trip} do
      conn = delete(conn, Routes.trips_path(conn, :delete, trip.id))
      assert redirected_to(conn) == "/trips"

      refute Copilot.Repo.get(Copilot.Itineraries.Trip, trip.id)
    end
  end
end

defmodule CopilotWeb.TripsController do
  @moduledoc false

  use CopilotWeb, :controller

  alias Copilot.Itineraries

  plug :fetch_current_trip when action in [:show, :edit, :update, :delete]

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(%{assigns: %{current_user: current_user}} = conn, _params) do
    trips = Itineraries.find_trips_for_user(current_user)

    render(conn, "index.html", trips: trips)
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    trip = Itineraries.find_trip_by_user_and_id(conn.assigns.current_user, id)

    render(conn, "show.html", trip: trip)
  end

  @spec new(Plug.Conn.t(), any) :: Plug.Conn.t()
  def new(%{assigns: %{current_user: current_user}} = conn, _params) do
    changeset = Itineraries.create_trip_changeset(%Itineraries.Trip{}, current_user)
    render(conn, "new.html", changeset: changeset)
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(%{assigns: %{current_user: current_user}} = conn, %{"trip" => trip_params}) do
    case Itineraries.create_trip(trip_params, current_user) do
      {:ok, trip} ->
        conn
        |> redirect(to: Routes.trips_path(conn, :show, trip.id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  @spec edit(Plug.Conn.t(), any) :: Plug.Conn.t()
  def edit(%{assigns: %{current_trip: current_trip}} = conn, _params) do
    changeset = Itineraries.update_trip_changeset(current_trip)
    render(conn, "edit.html", changeset: changeset)
  end

  @spec update(Plug.Conn.t(), map) :: Plug.Conn.t()
  def update(%{assigns: %{current_trip: current_trip}} = conn, %{"trip" => trip_params}) do
    case Itineraries.update_trip(current_trip, trip_params) do
      {:ok, trip} ->
        conn
        |> redirect(to: Routes.trips_path(conn, :show, trip.id))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", changeset: changeset)
    end
  end

  def delete(%{assigns: %{current_trip: current_trip}} = conn, _params) do
    case Itineraries.destroy_trip(current_trip) do
      {:ok, _trip} ->
        conn
        |> redirect(to: Routes.trips_path(conn, :index))

      {:error, %Ecto.Changeset{} = _changeset} ->
        conn
        |> redirect(to: Routes.trips_path(conn, :edit, current_trip.id))
    end
  end

  defp fetch_current_trip(
         %{assigns: %{current_user: current_user}, params: %{"id" => id}} = conn,
         _params
       ) do
    trip = Itineraries.find_trip_by_user_and_id(current_user, id)

    conn
    |> assign(:current_trip, trip)
  end
end

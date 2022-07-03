defmodule CopilotWeb.TripsController do
  @moduledoc false

  use CopilotWeb, :controller

  alias Copilot.Itineraries

  @spec index(Plug.Conn.t(), any) :: Plug.Conn.t()
  def index(conn, _opts) do
    render(conn, "index.html", trips: Itineraries.find_trips_for_user(conn.assigns.current_user))
  end

  @spec show(Plug.Conn.t(), map) :: Plug.Conn.t()
  def show(conn, %{"id" => id}) do
    trip = Itineraries.find_trip_by_user_and_id(conn.assigns.current_user, id)

    render(conn, "show.html", trip: trip)
  end
end

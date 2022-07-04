defmodule CopilotWeb.PageController do
  use CopilotWeb, :controller

  def index(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: Routes.trips_path(conn, :index))
    else
      render(conn, "index.html")
    end
  end
end

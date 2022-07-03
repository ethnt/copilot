defmodule CopilotWeb.PageControllerTest do
  @moduledoc false

  use CopilotWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Copilot"
  end
end

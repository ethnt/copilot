defmodule CopilotWeb.SessionsController do
  @moduledoc false

  use CopilotWeb, :controller

  alias Copilot.Accounts
  alias CopilotWeb.Authentication

  @spec new(Plug.Conn.t(), any) :: Plug.Conn.t()
  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  @spec create(Plug.Conn.t(), map) :: Plug.Conn.t()
  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = Accounts.find_user_by_email_and_password(email, password) do
      Authentication.login_user(conn, user, user_params)
    else
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  @spec destroy(Plug.Conn.t(), any) :: Plug.Conn.t()
  def destroy(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully")
    |> Authentication.logout_user()
  end
end

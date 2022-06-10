defmodule Copilot.Factory do
  @moduledoc """
  Includes functions to easily create objects for tests or in development
  """

  use ExMachina.Ecto, repo: Copilot.Repo

  @spec user_factory() :: %Copilot.Accounts.User{}
  def user_factory do
    %Copilot.Accounts.User{
      name: "Ernest Shackleton",
      email: sequence(:email, &"email-#{&1}@example.com"),
      hashed_password: Argon2.hash_pwd_salt("copilot123"),
      confirmed_at: ~N[2022-05-05 09:00:00]
    }
  end

  @spec trip_factory :: %Copilot.Itineraries.Trip{}
  def trip_factory do
    %Copilot.Itineraries.Trip{
      name: "Trip to Paris",
      description: "A trip to Paris!",
      start_date: ~D[2022-01-01],
      end_date: ~D[2022-02-01],
      user: build(:user)
    }
  end

  @spec past_trip_factory() :: %Copilot.Itineraries.Trip{}
  def past_trip_factory do
    today = Date.utc_today()

    struct!(
      trip_factory(),
      %{
        start_date: Date.add(today, -21),
        end_date: Date.add(today, -14)
      }
    )
  end

  @spec current_trip_factory() :: %Copilot.Itineraries.Trip{}
  def current_trip_factory do
    today = Date.utc_today()

    struct!(
      trip_factory(),
      %{
        start_date: Date.add(today, -7),
        end_date: Date.add(today, 7)
      }
    )
  end

  @spec future_trip_factory() :: %Copilot.Itineraries.Trip{}
  def future_trip_factory do
    today = Date.utc_today()

    struct!(
      trip_factory(),
      %{
        start_date: Date.add(today, 14),
        end_date: Date.add(today, 21)
      }
    )
  end
end

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

  @spec plan_factory :: %Copilot.Itineraries.Plan{}
  def plan_factory do
    %Copilot.Itineraries.Plan{
      canonical_start: DateTime.utc_now(),
      canonical_end: DateTime.utc_now(),
      trip: build(:trip)
    }
  end

  @spec activity_factory :: Copilot.Itineraries.Activity.t()
  def activity_factory do
    %Copilot.Itineraries.Activity{
      name: "Hiking",
      start_time: ~U[2022-01-01 20:00:00Z],
      end_time: ~U[2022-01-02 20:00:00Z]
    }
  end

  @spec activity_plan_factory :: Copilot.Itineraries.Plan.t()
  def activity_plan_factory do
    struct!(
      plan_factory(),
      %{
        attributes: activity_factory()
      }
    )
  end

  @spec flight_factory :: Copilot.Itineraries.Flight.t()
  def flight_factory do
    %Copilot.Itineraries.Flight{
      booking_reference: "ABCDE",
      flight_segments: build_list(3, :flight_segment)
    }
  end

  @spec flight_segment_factory :: Copilot.Itineraries.FlightSegment.t()
  def flight_segment_factory do
    %Copilot.Itineraries.FlightSegment{
      airline: "SAS",
      number: "123",
      origin: "JFK",
      destination: "CPH",
      departure_time: sequence(:flight_time, &(DateTime.utc_now() |> DateTime.add(&1, :second))),
      arrival_time: sequence(:flight_time, &(DateTime.utc_now() |> DateTime.add(&1, :second)))
    }
  end
end

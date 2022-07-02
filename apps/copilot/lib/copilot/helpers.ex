defmodule Copilot.Helpers do
  @moduledoc false

  import Ecto.Changeset, only: [get_field: 2, add_error: 3]

  @doc """
  Changeset validation for checking that the start date and end date are in the correct order
  """
  @spec validate_date_order(Ecto.Changeset.t(), atom(), atom(), String.t()) :: Ecto.Changeset.t()
  def validate_date_order(
        changeset,
        start_key \\ :start_date,
        end_key \\ :end_date,
        message \\ "must be after the start date"
      ) do
    with %Date{} = start_date <- get_field(changeset, start_key),
         %Date{} = end_date <- get_field(changeset, end_key) do
      if Date.compare(start_date, end_date) == :gt do
        add_error(changeset, end_key, message)
      else
        changeset
      end
    else
      _ -> changeset
    end
  end

  @doc """
  Changeset validation for checking that the start time and end time are in the correct order
  """
  @spec validate_time_order(Ecto.Changeset.t(), atom(), atom(), String.t()) :: Ecto.Changeset.t()
  def validate_time_order(
        changeset,
        start_key \\ :start_time,
        end_key \\ :end_time,
        message \\ "must be after the start time"
      ) do
    with %DateTime{} = start_time <- get_field(changeset, start_key),
         %DateTime{} = end_time <- get_field(changeset, end_key) do
      if DateTime.compare(start_time, end_time) == :gt do
        add_error(changeset, end_key, message)
      else
        changeset
      end
    else
      _ -> changeset
    end
  end
end

defmodule Copilot.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Copilot.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias Copilot.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Copilot.Factory
      import Copilot.DataCase
      import Copilot.TestHelpers
    end
  end

  setup tags do
    Copilot.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Sandbox.start_owner!(Copilot.Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  @spec errors_on(Ecto.Changeset.t()) :: map()
  def errors_on(changeset) do
    PolymorphicEmbed.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @spec map_ids([Ecto.Schema.t()]) :: [integer()]
  def map_ids(records) do
    Enum.map(records, fn r -> r.id end)
  end

  @spec matching_ids([Ecto.Schema.t()], [Ecto.Schema.t()]) :: boolean()
  def matching_ids(expected, actual) do
    expected_ids = map_ids(expected)
    actual_ids = map_ids(actual)

    Enum.sort(expected_ids) == Enum.sort(actual_ids)
  end

  @spec matching_ordered_ids([Ecto.Schema.t()], [Ecto.Schema.t()]) :: boolean()
  def matching_ordered_ids(expected, actual) do
    expected_ids = map_ids(expected)
    actual_ids = map_ids(actual)

    expected_ids == actual_ids
  end
end

ExUnit.configure(timeout: 1_000_000_000)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Copilot.Repo, :manual)

defmodule Mix.Tasks.ZiglerTest do
  use Mix.Task

  @shortdoc "Tests Zigler functions without starting Phoenix"
  def run(_) do
    # Ensure app is loaded but not started
    Mix.Task.run("app.config")

    # Call your Zigler functions here
    result = Codeforces.Client.arenaSum([1, 2, 3])
    IO.puts("Result: #{inspect(result)}")

    result = Codeforces.Client.contestList()
    IO.puts("Result: #{inspect(result)}")
  end
end

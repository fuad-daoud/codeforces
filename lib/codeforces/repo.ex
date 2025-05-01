defmodule Codeforces.Repo do
  use Ecto.Repo,
    otp_app: :codeforces,
    adapter: Ecto.Adapters.Postgres
end

defmodule Codeforces.Client do
  use Memoize

  defmemo get_contest_list(client \\ __MODULE__), expires_in: 60 * 60 * 1000 do
    client.get("/contest.list")
  end

  defmemo get_contest_standings(client \\ __MODULE__, id, handles), expires_in: 60 * 60 * 1000 do
    client.get(
      "/contest.standings?showUnofficial=true&contestId=#{id}&handles=#{handles}&participantTypes=CONTESTANT,PRACTICE,VIRTUAL,OUT_OF_COMPETITION"
    )
  end

  def get(path, _ \\ %{}) do
    base_url = "https://codeforces.com/api"

    HTTPoison.get("#{base_url}#{path}")
    |> handle_response()
  end

  defp handle_response({:ok, %{status_code: status, body: body}}) when status in 200..299 do
    {:ok, Jason.decode!(body)}
  end

  defp handle_response({:ok, %{status_code: status, body: body}}) do
    {:error, %{status: status, body: body}}
  end

  defp handle_response({:error, %{reason: reason}}) do
    {:error, %{reason: reason}}
  end
end

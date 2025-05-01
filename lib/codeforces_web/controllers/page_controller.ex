defmodule CodeforcesWeb.PageController do
  alias Codeforces.Client
  use CodeforcesWeb, :controller

  def home(conn, _params) do
    {status, response} = Client.get_contest_list()

    status |> IO.inspect()

    if status == nil do
      raise "status is nil, something wrong"
    end

    contests =
      response["result"]
      |> Enum.filter(fn contest ->
        contest["name"]
        |> String.starts_with?("Educational")
      end)
      |> Enum.slice(1, 10)
      |> Enum.map(fn contest ->
        {_, response} = Client.get_contest_standings(contest["id"], "immortalfox;gon")

        problems =
          response["result"]["problems"]
          |> Enum.map(fn problem -> problem["index"] end)

        result =
          response["result"]["rows"]
          |> Enum.map(fn row ->
            %{
              handle: (row["party"]["members"] |> Enum.at(0))["handle"],
              problems: row["problemResults"] |> Enum.map(fn p -> p["points"] end)
            }
          end)
          |> Enum.group_by(fn row -> row.handle end)
          |> Enum.map(fn {k, v} ->
            zipped =
              v
              |> Enum.reduce([], fn row, acc ->
                case acc do
                  [] ->
                    row.problems

                  _ ->
                    Enum.zip_with([acc, row.problems], fn [a, b] ->
                      case [a, b] do
                        [0.0, 0.0] -> 0.0
                        [_, _] -> 1.0
                      end
                    end)
                end
              end)

            {k, zipped}
          end)
          |> Map.new()
          |> Enum.map(fn {k, v} ->
            solved =
              Enum.zip_with([v, problems], fn [x, problem] ->
                case x do
                  1.0 -> problem
                  _ -> nil
                end
              end)
              |> Enum.filter(fn x -> x != nil end)

            unsolved =
              Enum.zip_with([v, problems], fn [x, problem] ->
                case x do
                  0.0 -> problem
                  _ -> nil
                end
              end)
              |> Enum.filter(fn x -> x != nil end)

            %{k => %{"solved" => solved, "unsolved" => unsolved}}
          end)
          |> Enum.reduce(%{}, fn x, acc ->
            Map.merge(x, acc)
          end)
          |> Map.merge(%{
            "name" => contest["name"],
            "link" => "https://codeforces.com/contest/#{contest["id"]}"
          })

        result =
          if !Map.has_key?(result, "gon") do
            Map.put(result, "gon", %{"solved" => [], "unsolved" => problems})
          else
            result
          end

        result =
          if !Map.has_key?(result, "immortalfox") do
            Map.put(result, "immortalfox", %{"solved" => [], "unsolved" => problems})
          else
            result
          end
      end)

    render(conn, :home, %{
      contests: contests
    })
  end
end

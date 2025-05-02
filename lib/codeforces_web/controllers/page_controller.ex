defmodule CodeforcesWeb.PageController do
  alias Codeforces.Client
  alias Codeforces.Context
  use CodeforcesWeb, :controller

  def home(conn, _params) do
    {status, response} = Client.get_contest_list()

    status |> IO.inspect()

    if status == nil do
      raise "status is nil, something wrong"
    end

    Context.transformContestData([%{id: 123, name: "123", newfield: "hi"}])

    render(conn, :home, %{
      contests: []
    })
  end
end

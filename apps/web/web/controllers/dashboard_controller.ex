defmodule Web.DashboardController do
  use Web.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def do_command(conn, params) do
    command = Domo.Node.get_commands(params["node"] |> String.to_existing_atom)
              |> Enum.find(fn([cmd_name | _rest]) -> cmd_name == params["command"] |> String.to_existing_atom end)

    [cmd_name | args] = command

    cmd_to_send = [cmd_name | args |> Enum.map(fn(arg) -> params[arg |> to_string] |> String.to_integer end)] |> List.to_tuple

    Process.send(params["node"] |> String.to_existing_atom, {:command, cmd_to_send}, [])

    redirect conn, to: "/"
  end
end

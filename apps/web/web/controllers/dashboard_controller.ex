defmodule Web.DashboardController do
  use Web.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def do_command(conn, params) do
    command = Domo.Node.get_commands(params["node"] |> String.to_existing_atom) |> IO.inspect |> Enum.find(fn([_, cmd_name | _rest]) -> cmd_name == params["command"] |> String.to_existing_atom end) |> IO.inspect
    [class, cmd_name | args] = command
    cmd_to_send = [cmd_name | args |> Enum.map(fn(arg) -> params[arg |> to_string] |> String.to_integer end)]
    Process.send(params["node"] |> String.to_existing_atom, cmd_to_send |> List.to_tuple, [])
    redirect conn, to: "/"
  end

  def set_value(conn, params) do
    value = params["value"] |> String.to_integer
    duration = params["duration"] |> String.to_integer
    Process.send(params["node"] |> String.to_existing_atom, {:set_level, value, duration}, [])
    redirect conn, to: "/"
  end


  def turn_on(conn, params) do
    Process.send(params["node"] |> String.to_existing_atom, {:set_level, 0x63, 0x02}, [])
    redirect conn, to: "/"
  end

  def turn_off(conn, params) do
    Process.send(params["node"] |> String.to_existing_atom, {:set_level, 0x00, 0x02}, [])
    redirect conn, to: "/"
  end
end

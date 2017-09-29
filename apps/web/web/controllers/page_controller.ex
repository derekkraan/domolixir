defmodule Web.PageController do
  use Web.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def turn_on(conn, params) do
    Process.send(params["node"] |> String.to_existing_atom, {:set_level, 0x63, 0x02}, [])
    render conn, "index.html"
  end

  def turn_off(conn, params) do
    Process.send(params["node"] |> String.to_existing_atom, {:set_level, 0x00, 0x02}, [])
    render conn, "index.html"
  end
end

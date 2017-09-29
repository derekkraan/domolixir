defmodule Web.NetworksController do
  use Web.Web, :controller

  def index(conn, _params) do
    IO.inspect conn |> get_req_header("referer")
    render conn, "index.html"
  end

  def start_network(conn, params) do
    Domo.Manager.start(params["network"])
    redirect conn, to: "/networks"
  end
end

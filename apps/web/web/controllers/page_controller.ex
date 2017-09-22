defmodule Web.PageController do
  use Web.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end

  def turn_on(conn, _params) do
    Process.send(:usb1_node_5, {:set_level, 0x20, 0x02}, [])
    render conn, "index.html"
  end

  def turn_off(conn, _params) do
    Process.send(:usb1_node_5, {:set_level, 0x00, 0x02}, [])
    render conn, "index.html"
  end
end

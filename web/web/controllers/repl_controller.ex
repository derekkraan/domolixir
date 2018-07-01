defmodule Web.REPLController do
  use Web.Web, :controller

  def repl(conn, params) do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)
    body_json = Poison.decode!(body)
    bindings = for {key, value} <- body_json["bindings"], do: {String.to_existing_atom(key), value}
    {output, bindings} = Code.eval_string(body_json["input"], bindings)
    json conn, %{output: inspect(output), bindings: Enum.into(bindings, %{})}
  end

  def index(conn, _params) do
    render conn, "index.html"
  end
end

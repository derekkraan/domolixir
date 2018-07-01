defmodule Web.EventLogController do
  use Web.Web, :controller

  def log(conn, params) do
    logs =
      Domo.EventListener.EventLog.empty_log()
      |> Enum.map(&inspect/1)
      |> Enum.map(fn str -> ">>> #{str}" end)
      |> Enum.join("\n\n")

    text(conn, logs)
  end
end

defmodule Web.EventLogController do
  use Web.Web, :controller

  def log(conn, params) do
    logs =
      RingLogger.next()
      |> Jason.encode!()

    text(conn, logs)
  end
end

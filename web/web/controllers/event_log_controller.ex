defmodule Web.EventLogController do
  use Web.Web, :controller

  def log(conn, params) do
    logs =
      RingLogger.get()
      |> Enum.map(fn {level, {_, msg, ts, mdata}} ->
        Logger.Formatter.format(
          Logger.Formatter.compile("[$level] $message"),
          level,
          msg,
          ts,
          mdata
        )
      end)
      |> Enum.map(&IO.chardata_to_string/1)
      |> Enum.join("\n")

    text(conn, logs)
  end
end

defmodule Web.EventLogController do
  use Web.Web, :controller

  def log(conn, params) do
    json conn, Domo.EventListener.EventLog.empty_log
  end
end

defmodule Web.Router do
  use Web.Web, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_flash)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :repl do
    plug(:accepts, ["json"])
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", Web do
    # Use the default browser stack
    pipe_through(:browser)

    get("/", DashboardController, :index)

    get("/log", EventLogController, :log)

    get("/scenes", ScenesController, :index)

    get("/dashboard", DashboardController, :index)
    get("/nodes", DashboardController, :nodes)
    post("/node/command", DashboardController, :node_command)
    post("/network/pair", DashboardController, :network_pair)
    post("/network/connect", DashboardController, :network_connect)
    get("/networks", DashboardController, :networks)
    post("/turn_on", DashboardController, :turn_on)
    post("/do_command", DashboardController, :do_command)
    post("/turn_off", DashboardController, :turn_off)
    post("/set_value", DashboardController, :set_value)
  end

  scope "/", Web do
    pipe_through(:repl)

    get("/repl", REPLController, :index)
    post("/repl", REPLController, :repl)
  end

  # Other scopes may use custom stacks.
  # scope "/api", Web do
  #   pipe_through :api
  # end
end

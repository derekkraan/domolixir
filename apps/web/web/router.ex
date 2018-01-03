defmodule Web.Router do
  use Web.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :repl do
    plug :accepts, ["json"]
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Web do
    pipe_through :browser # Use the default browser stack
    get "/", DashboardController, :index

    get "/log", EventLogController, :log

    get "/scenes", ScenesController, :index

    get "/dashboard", DashboardController, :index
    get "/nodes", DashboardController, :nodes
    get "/networks", DashboardController, :networks
    post "/turn_on", DashboardController, :turn_on
    post "/do_command", DashboardController, :do_command
    post "/turn_off", DashboardController, :turn_off
    post "/set_value", DashboardController, :set_value
  end

  scope "/", Web do
    pipe_through :repl

    get "/repl", REPLController, :index
    post "/repl", REPLController, :repl
  end


  # Other scopes may use custom stacks.
  # scope "/api", Web do
  #   pipe_through :api
  # end
end

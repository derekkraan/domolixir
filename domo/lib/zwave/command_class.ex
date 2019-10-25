defmodule ZWave.CommandClass do
  @callback start_link(name :: String.t(), node_id :: String.t()) :: nil | {:ok, pid}
  @callback commands() :: list(atom())
  @callback process_message(name :: String.t(), node_id :: String.t(), message :: binary()) ::
              any()
end

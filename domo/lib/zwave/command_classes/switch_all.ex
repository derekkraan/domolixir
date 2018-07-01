defmodule ZWave.SwitchAll do
  @behaviour ZWave.CommandClass

  def commands, do: []
  def start_link(name, node_id), do: nil
  def process_message(_, _, _), do: nil
end

defmodule ZWave.MultiInstance do
  @behaviour ZWave.CommandClass
  require Logger
  use GenServer

  @command_class 0x27

  # I don't know what this command class id is for but it's there.
  @command_class_id 0x60

  @name "MultiInstance"

  use ZWave.Constants

  def start_link(name, node_id),
    do: GenServer.start_link(__MODULE__, {name, node_id}, name: process_name(name, node_id))

  def process_message(name, node_id, message),
    do: send(process_name(name, node_id), {:message_from_zstick, message})

  def process_name(name, node_id), do: :"#{ZWave.Node.node_name(name, node_id)}_#{__MODULE__}"

  def commands do
    []
  end

  defmodule State do
    defstruct name: nil, node_id: nil
  end

  def command_class, do: @command_class

  def init({name, node_id}) do
    Logger.debug("Starting MULTIINSTANCE")
    state = %State{name: name, node_id: node_id}
    ZWave.ZStick.queue_command(name, request_instances(state))

    {:ok, state}
  end

  @multi_instance_cmd_get 0x04
  @multi_instance_cmd_report 0x05
  @multi_instance_cmd_encap 0x06
  @multi_channel_cmd_endpoint_get 0x07
  @multi_channel_cmd_endpoint_report 0x08
  @multi_channel_cmd_capability_get 0x09
  @multi_channel_cmd_capability_report 0x0A
  @multi_channel_cmd_endpoint_find 0x0B
  @multi_channel_cmd_endpoint_find_report 0x0C
  @multi_channel_cmd_encap 0x0D

  def request_instances(state) do
    %ZWave.Msg{
      type: @request,
      function: @func_id_zw_send_data,
      data: [state.node_id, 0x03, @command_class, @multi_instance_cmd_get, @command_class_id],
      target_node_id: state.node_id
    }
  end

  def handle_info(
        {:message_from_zstick,
         <<@sof, _length, @response, @func_id_zw_get_node_protocol_info, _rest::binary>>},
        {:noreply, state}
      ) do
  end

  # <<1, 9, 1, 65, 147, 22, 1, 2, 2, 1, 51>>
  # def handle_info({:message_from_zstick, <<@sof, _length, 

  def handle_info({:message_from_zstick, msg}, state) do
    Logger.debug("got unknown message #{inspect(msg)} in #{__MODULE__} for node #{state.node_id}")
    {:noreply, state}
  end
end

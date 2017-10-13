defmodule ZWave.Association do
  use ZWave.Constants
  use GenServer
  require Logger

  @command_class 0x85
  @name "Association"

  defmodule State, do: defstruct [:name, :node_id, :number_association_groups, :associations_initialized]
  @init_state %{associations_initialized: false}

  def process_message(name, node_id, message), do: Process.send(process_name(name, node_id), {:message_from_zstick, message}, [])

  @associationcmd_set 0x01
  @associationcmd_get 0x02
  @associationcmd_report 0x03
  @associationcmd_remove 0x04
  @associationcmd_groupingsget 0x05
  @associationcmd_groupingsreport 0x06

  def start_link(name, node_id) do
    Logger.debug "STARTING ASSOCIATION"
    GenServer.start_link(__MODULE__, {name, node_id}, name: process_name(name, node_id)) |> IO.inspect
  end

  def init({name, node_id}) do
    state = %State{} |> Map.merge(@init_state) |> Map.merge(%{node_id: node_id, name: name})
    association_groupings_get_command(name, node_id) |> ZWave.ZStick.queue_command(name)
    {:ok, state}
  end

  def process_name(name, node_id), do: :"#{ZWave.Node.node_name(name, node_id)}_association_command_class"

  def add_command_class(node_state), do: node_state |> Map.put(:command_classes, [@command_class | node_state.command_classes])

  def commands, do: [
    [:association_groupings_get],
    [:association_set, :to_node_id, :group_id],
  ]

  # def handle({:association_groupings_get}, node_id), do: association_groupings_get_command(node_id)

  def association_groupings_get_command(name, node_id) do
    callback_id = GenServer.call(name, :get_callback_id)
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, callback_id: callback_id, data: [node_id, 0x02, @command_class, @associationcmd_groupingsget, ZWave.ZStick.transmit_options], target_node_id: node_id, expected_response: @func_id_application_command_handler}
  end

  def add_associations(state = %{associations_initialized: true}), do: state
  def add_associations(state) do
    %{controller_node_id: controller_node_id} = GenServer.call(state.name, :get_information)
    (1..state.number_association_groups) |> Enum.each(fn(group_id) ->
      Logger.debug "setting association #{group_id}"
      association_set_command(controller_node_id, group_id, state.node_id) |> ZWave.ZStick.queue_command(state.name)
    end)
    state
  end

  # def handle({:association_set, to_node_id, group_id}, node_id) do
  #   association_set_command(to_node_id, group_id, node_id) |> ZWave.ZStick.queue_command(name)
  # end

  def association_set_command(to_node_id, group_id, node_id) do
    %ZWave.Msg{type: @request, function: @func_id_zw_send_data, data: [node_id, 0x04, @command_class, @associationcmd_set, group_id, to_node_id], target_node_id: node_id}
  end

  def process_message(name, node_id, message), do: Process.send(process_name(name, node_id), {:message_from_zstick, message}, [])

  def handle_info({:message_from_zstick, message}, state) do
    {:noreply, private_process_message(state, message)}
  end

  def private_process_message(state, <<@sof, _length, @request, @func_id_application_command_handler, _callback_id, node_id, 3, @command_class, @associationcmd_groupingsreport, num_groups, _checksum>>) do
    Logger.debug "Number of association groups for #{node_id} is #{num_groups}"
    %State{state | number_association_groups: num_groups} |> add_associations()
  end

  def private_process_message(state, _message), do: state
end

  #
  # FROM node.ex
  # TODO integrate this into `ZWave.Association`
  #
  # def handle_info({:update_state, %ZWave.Node{number_association_groups: number_association_groups}}, state) do
  #   %{controller_node_id: controller_node_id} = GenServer.call(state.name, :get_information)
  #   (1..number_association_groups) |> Enum.each(fn(group_id) ->
  #     Logger.debug "setting association #{group_id}"
  #     ZWave.CommandClasses.dispatch_command({:association_set, controller_node_id, group_id}, state.node_id) |> do_cmd(state)
  #   end)
  #   {:noreply, %ZWave.Node{state | number_association_groups: number_association_groups}}
  # end
  # def handle_info({:update_state, new_state = %ZWave.Node{}}, state) do
  #   {:noreply, state |> Map.merge(new_state)}
  # end


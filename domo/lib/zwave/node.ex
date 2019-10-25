defmodule ZWave.Node do
  require Logger

  use GenServer
  use ZWave.Constants

  defstruct alive: true,
            total_errors: 0,
            node_id: nil,
            name: nil,
            capabilities: nil,
            listening: nil,
            frequent_listening: nil,
            basic_class: nil,
            generic_class: nil,
            specific_class: nil,
            command_classes: [],
            command_class_modules: [],
            generic_label: nil,
            specific_label: nil,
            label: nil,
            number_association_groups: nil,
            initialized: false

  @securityflag_security 0x01
  @securityflag_controller 0x02
  @securityflag_specificdevice 0x04
  @securityflag_routingslave 0x08
  @securityflag_beamcapability 0x10
  @securityflag_sensor250ms 0x20
  @securityflag_sensor1000ms 0x40
  @securityflag_optionalfunctionality 0x80

  def start_link(name, node_id) do
    Logger.debug("STARTING NODE #{node_name(name, node_id)}")
    GenServer.start_link(__MODULE__, {name, node_id}, name: node_name(name, node_id))
  end

  def start(controller_name, node_id) do
    import Supervisor.Spec

    Supervisor.start_child(
      ZWave.ZStick.network_supervisor_name(controller_name),
      worker(
        __MODULE__,
        [controller_name, node_id],
        id: node_name(controller_name, node_id)
      )
    )
    |> case do
      {:ok, _child} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      error -> error |> IO.inspect()
    end
  end

  def stop(controller_name, node_id) do
    :ok =
      Supervisor.terminate_child(
        ZWave.ZStick.network_supervisor_name(controller_name),
        node_name(controller_name, node_id)
      )

    :ok =
      Supervisor.delete_child(
        ZWave.ZStick.network_supervisor_name(controller_name),
        node_name(controller_name, node_id)
      )
  end

  def init({name, node_id}) do
    state = %ZWave.Node{node_id: node_id, name: name}

    %{
      event_type: "node_added",
      network_identifier: name,
      node_identifier: node_name(name, node_id),
      commands: []
    }
    |> EventBus.send()

    request_state(state)
    {:ok, state}
  end

  def node_name(name, node_id), do: :"#{name}_node_#{node_id}"

  #
  # -- messages from controller --
  #
  def handle_call({:command, command}, _from, state) do
    Logger.debug("RECEIVED COMMAND #{command |> inspect}")

    case ZWave.CommandClasses.dispatch_command(command, state.node_id) do
      nil -> nil
      cmd -> do_cmd(cmd, state)
    end

    {:reply, :ok, state}
  end

  def handle_info({:command, cmd}, state) do
    Logger.debug("RECEIVED COMMAND #{cmd |> inspect}")

    case ZWave.CommandClasses.dispatch_command(cmd, state.node_id) do
      nil -> nil
      cmd -> do_cmd(cmd, state)
    end

    {:noreply, state}
  end

  #
  # -- messages from ZStick --
  #
  def handle_info({:message_from_zstick, message}, state) do
    Logger.debug("GOT MESSAGE IN NODE #{state.node_id}: #{message |> inspect}")
    state = process_message(state, message)

    state.command_class_modules
    |> Enum.map(fn module ->
      module.process_message(state.name, state.node_id, message)
    end)

    {:noreply, %{state | total_errors: 0}}
  end

  def handle_info({:zstick_send_error, command}, state = %{listening: 0}) do
    send(ZWave.WakeUp.process_name(state.name, state.node_id), {:queue_command, command})
    {:noreply, state}
  end

  def handle_info({:zstick_send_error, command}, state = %{total_errors: total_errors})
      when total_errors > 10 do
    # try again in 10 minutes
    Process.send_after(self(), {:retry_message, command}, 1000 * 60 * 10, [])

    %{
      event_type: "node_alive",
      alive: false,
      node_identifier: node_name(state.name, state.node_id)
    }
    |> EventBus.send()

    {:noreply, %{state | alive: false, total_errors: state.total_errors + 1}}
  end

  def handle_info({:zstick_send_error, command}, state) do
    command = ZWave.Msg.update_backoff_time(command)
    Process.send_after(self(), {:retry_message, command}, command.backoff_time, [])
    {:noreply, %{state | total_errors: state.total_errors + 1}}
  end

  def handle_info({:retry_message, command}, state) do
    ZWave.ZStick.queue_command(state.name, command)
    {:noreply, state}
  end

  defp do_cmd(cmd, state) do
    # TODO: is setting target_node_id correct here?
    ZWave.ZStick.queue_command(state.name, %ZWave.Msg{cmd | target_node_id: state.node_id})
  end

  defp add_command_classes(%{command_classes: command_classes} = state) do
    add_command_classes(state, command_classes)
  end

  defp add_command_classes(state, []), do: state

  defp add_command_classes(state, [command_class | command_classes]) do
    add_command_class(state, command_class)
    |> add_command_classes(command_classes)
  end

  defp add_command_class(state, command_class) do
    Logger.debug(inspect(state.command_classes))
    Logger.debug("add command class #{inspect(command_class)} for node #{state.node_id}?")
    command_class_module = ZWave.CommandClasses.command_class(command_class)

    if !Enum.member?(state.command_class_modules, command_class_module) do
      Logger.debug("starting #{inspect(command_class_module)} for node #{state.node_id}")
      command_class_module.start_link(state.name, state.node_id)

      %ZWave.Node{
        state
        | command_classes: [command_class | state.command_classes],
          command_class_modules: [command_class_module | state.command_class_modules]
      }
      |> notify_commands()
    else
      state
    end
  end

  defp notify_commands(state) do
    commands =
      state.command_classes
      |> Enum.flat_map(fn command_class ->
        ZWave.CommandClasses.command_class(command_class).commands
      end)

    %{
      event_type: "node_has_commands",
      commands: commands,
      node_identifier: node_name(state.name, state.node_id)
    }
    |> EventBus.send()

    state
  end

  defp process_message(
         state,
         <<@sof, _msglength, @request, @func_id_application_command_handler, _status, node_id,
           _length, command_class, _rest::binary>>
       ) do
    add_command_class(state, command_class)
  end

  defp process_message(
         state,
         <<@sof, _length, @response, @func_id_zw_get_node_protocol_info, _cap, _freq, _some,
           _basic, 0, _rest::binary>>
       ) do
    %{
      event_type: "node_alive",
      alive: false,
      node_identifier: node_name(state.name, state.node_id)
    }
    |> EventBus.send()

    %{state | alive: false}
  end

  defp process_message(
         state = %{initialized: false},
         <<@sof, _length, @response, @func_id_zw_get_node_protocol_info, capabilities,
           frequent_listening, _something, basic_class, generic_class, specific_class, _checksum>>
       ) do
    use Bitwise

    ZWave.ZStick.queue_command(state.name, ZWave.NoOperation.noop_command(state.node_id))

    %{
      event_type: "node_alive",
      alive: true,
      node_identifier: node_name(state.name, state.node_id)
    }
    |> EventBus.send()

    Logger.info(
      "#{state.node_id}: #{
        inspect(OpenZWaveConfig.get_information(generic_class, specific_class))
      }"
    )

    %ZWave.Node{
      state
      | alive: true,
        listening: capabilities &&& 0x80,
        frequent_listening:
          frequent_listening &&& @securityflag_sensor250ms ^^^ @securityflag_sensor1000ms,
        capabilities: capabilities,
        basic_class: basic_class,
        generic_class: generic_class,
        specific_class: specific_class,
        initialized: true
    }
    |> Map.merge(OpenZWaveConfig.get_information(generic_class, specific_class))
    |> add_command_classes()
    |> add_wakeup_command_class()
    |> add_command_class(ZWave.NoOperation.command_class())
    |> add_command_class(ZWave.Association.command_class())
  end

  defp process_message(state, _msg), do: state

  defp add_wakeup_command_class(state = %{listening: 0}),
    do: state |> add_command_class(ZWave.WakeUp.command_class())

  defp add_wakeup_command_class(state), do: state

  defp request_state(state) do
    ZWave.ZStick.queue_command(state.name, %ZWave.Msg{
      type: @request,
      function: @func_id_zw_get_node_protocol_info,
      data: [state.node_id],
      target_node_id: state.node_id
    })

    state
  end
end

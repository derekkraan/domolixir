defmodule ZStick.Node do
  use GenServer
  use ZStick.Constants

  defstruct [
    :alive,
    :node_id,
    :name,
  ]

  def start_link(name, node_id) do
    GenServer.start_link(__MODULE__, {name, node_id}, name: node_name(name, node_id))
  end

  def nodes_in_bytes(bytes, offset\\0, nodes\\[])
  def nodes_in_bytes(<<>>, _offset, nodes), do: nodes
  def nodes_in_bytes(<<byte, bytes::binary>>, offset, nodes) do
    nodes_in_bytes(bytes, offset + 8, nodes_in_byte(byte) ++ nodes)
  end
  def nodes_in_byte(byte, offset\\0, nodes\\[])
  def nodes_in_byte(byte, 8, nodes), do: nodes
  def nodes_in_byte(byte, offset, nodes) do
    use Bitwise
    if (byte &&& (1 <<< offset)) != 0 do
      nodes_in_byte(byte, offset + 1, [offset + 1 | nodes])
    else
      nodes_in_byte(byte, offset + 1, nodes)
    end
  end

  def set_up_nodes(state) do
    set_up_nodes(state, nodes_in_bytes(<<state.node_bitfield::size(@max_num_nodes)>>))
  end
  def set_up_nodes(_state, []), do: nil
  def set_up_nodes(state, [node_id | other_node_ids]) do
    import Supervisor.Spec

    IO.puts "START NODE #{node_id}"

    {:ok, _child} = Supervisor.start_child(ZStick.supervisor_name(state.name), worker(ZStick.Node, [state.name, node_id], [id: ZStick.Node.node_name(state.name, node_id)]))
    set_up_nodes(state, other_node_ids)
  end

  def init({name, node_id}) do
    state = %ZStick.Node{alive: true, node_id: node_id, name: name}
    request_state(state)
    {:ok, state}
  end

  def node_name(name, node_id), do: :"#{name}_node_#{node_id}"

  def request_state(state) do
    %ZStick.Msg{type: @request, function: @func_id_zw_get_node_protocol_info, data: [state.node_id], target_node_id: state.node_id}
    |> ZStick.queue_command(state.name)
  end
end

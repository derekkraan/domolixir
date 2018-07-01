defmodule TurnOnForResponderTest do
  use ExUnit.Case

  defmodule TestRecorder do
    use GenServer

    def init(test_pid) do
      {:ok, test_pid}
    end

    def handle_call(msg, _from, test_pid) do
      Kernel.send(test_pid, msg)
      {:reply, :ok, test_pid}
    end
  end

  setup do
    {:ok, recorder_pid} = GenServer.start_link(TestRecorder, self(), [])

    {:ok, pid} =
      Domo.EventListener.TurnOnForResponder.start_link(
        %{event_type: "TestEvent", node_id: "foo"},
        {recorder_pid, {:turn_on}},
        {recorder_pid, {:turn_off}},
        10
      )

    [pid: pid]
  end

  test "Matches pattern", context do
    send(context[:pid], {:event, %{event_type: "TestEvent", node_id: "foo"}})
    assert_receive({:command, {:turn_on}}, 100)
    assert_receive({:command, {:turn_off}}, 100)
  end

  test "multiple matches", context do
    send(context[:pid], {:event, %{event_type: "TestEvent", node_id: "foo"}})
    send(context[:pid], {:event, %{event_type: "TestEvent", node_id: "foo"}})
    assert_receive({:command, {:turn_on}}, 100)
    assert_receive({:command, {:turn_off}}, 100)
  end

  test "Partial match", context do
    send(
      context[:pid],
      {:event, %{event_type: "TestEvent", node_id: "foo", info: "not included in match"}}
    )

    assert_receive({:command, {:turn_on}}, 100)
    assert_receive({:command, {:turn_off}}, 100)
  end

  test "No match", context do
    send(context[:pid], {:event, %{event_type: "NoMatchEvent", node_id: "foo"}})
    refute_receive({:command, {:turn_on}}, 100)
    refute_receive({:command, {:turn_off}}, 100)
  end
end

defmodule TurnOnForResponderTest do
  use ExUnit.Case

  setup do
    {:ok, pid} = Domo.EventListener.TurnOnForResponder.start_link(%{event_type: "TestEvent", node_id: "foo"}, {self(), {:turn_on}}, {self(), {:turn_off}}, 10)
    [pid: pid]
  end

  test "Matches pattern", context do
    send(context[:pid], {:event, %{event_type: "TestEvent", node_id: "foo"}})
    assert_receive({:turn_on}, 100)
    assert_receive({:turn_off}, 100)
  end

  test "multiple matches", context do
    send(context[:pid], {:event, %{event_type: "TestEvent", node_id: "foo"}})
    send(context[:pid], {:event, %{event_type: "TestEvent", node_id: "foo"}})
    assert_receive({:turn_on}, 100)
    assert_receive({:turn_off}, 100)
  end

  test "Partial match", context do
    send(context[:pid], {:event, %{event_type: "TestEvent", node_id: "foo", info: "not included in match"}})
    assert_receive({:turn_on}, 100)
    assert_receive({:turn_off}, 100)
  end

  test "No match", context do
    send(context[:pid], {:event, %{event_type: "NoMatchEvent", node_id: "foo"}})
    refute_receive({:turn_on}, 100)
    refute_receive({:turn_off}, 100)
  end
end

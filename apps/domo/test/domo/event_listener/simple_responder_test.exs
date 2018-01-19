defmodule SimpleResponderTest do
  use ExUnit.Case

  setup do
    {:ok, pid} =
      Domo.EventListener.SimpleResponder.start_link(
        %{event_type: "TestEvent", node_id: "foo"},
        {self(), {:got_event}}
      )

    [pid: pid]
  end

  test "Matches pattern", context do
    send(context[:pid], {:event, %{event_type: "TestEvent", node_id: "foo"}})
    assert_receive({:got_event}, 100)
  end

  test "Partial match", context do
    send(
      context[:pid],
      {:event, %{event_type: "TestEvent", node_id: "foo", info: "not included in match"}}
    )

    assert_receive({:got_event}, 100)
  end

  test "No match", context do
    send(context[:pid], {:event, %{event_type: "NoMatchEvent", node_id: "foo"}})
    refute_receive({:got_event}, 100)
  end
end

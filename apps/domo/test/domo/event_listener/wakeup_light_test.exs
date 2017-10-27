defmodule WakeupLightTest do
  use ExUnit.Case

  setup context do
    {:ok, normal_time_pid} = Domo.EventListener.WakeupLight.start_link(%Domo.EventListener.WakeupLight{time: [hour: 17, minute: 15], days_of_week: ["Fri"], light_intensity: 50, minutes_to_fade_in: 30, node_id: self()})
    {:ok, just_after_midnight_pid} = Domo.EventListener.WakeupLight.start_link(%Domo.EventListener.WakeupLight{time: [hour: 00, minute: 15], days_of_week: ["Fri"], light_intensity: 50, minutes_to_fade_in: 30, node_id: self()})
    [normal_time_pid: normal_time_pid, just_after_midnight_pid: just_after_midnight_pid]
  end

  test "doesn't turn on a light if it isn't time yet", context do
    day = Timex.now() |> Timex.set([year: 2017, month: 10, day: 27, hour: 14, minute: 0])
    send(context[:normal_time_pid], {:event, %{event_type: "clock_update", node_id: nil, datetime: day}})
    refute_receive(_)
  end

  test "wrong day (Saturday)", context do
    day = Timex.now() |> Timex.set([year: 2017, month: 10, day: 28, hour: 14, minute: 0])
    send(context[:normal_time_pid], {:event, %{event_type: "clock_update", node_id: nil, datetime: day}})
    refute_receive(_)
  end

  test "turns on a light when the time is approaching", context do
    day = Timex.now() |> Timex.set([year: 2017, month: 10, day: 27, hour: 16, minute: 45])
    send(context[:normal_time_pid], {:event, %{event_type: "clock_update", node_id: nil, datetime: day}})
    assert_receive({:command, {:basic_set, _}})
  end

  test "when fadein time begins, sets the lamp to 0", context do
    day = Timex.now() |> Timex.set([year: 2017, month: 10, day: 27, hour: 16, minute: 45])
    send(context[:normal_time_pid], {:event, %{event_type: "clock_update", node_id: nil, datetime: day}})
    assert_receive({:command, {:basic_set, 0}})
  end

  test "when halfway through fadein time, sets the lamp to 50% of final intensity", context do
    day = Timex.now() |> Timex.set([year: 2017, month: 10, day: 27, hour: 17, minute: 00])
    send(context[:normal_time_pid], {:event, %{event_type: "clock_update", node_id: nil, datetime: day}})
    assert_receive({:command, {:basic_set, 25}})
  end

  test "works across days", context do
    day = Timex.now() |> Timex.set([year: 2017, month: 10, day: 26, hour: 23, minute: 51])
    send(context[:just_after_midnight_pid], {:event, %{event_type: "clock_update", node_id: nil, datetime: day}})
    assert_receive({:command, {:basic_set, 10}})
  end

  test "still checks day of week properly across dates", context do
    day = Timex.now() |> Timex.set([year: 2017, month: 10, day: 25, hour: 23, minute: 51])
    send(context[:just_after_midnight_pid], {:event, %{event_type: "clock_update", node_id: nil, datetime: day}})
    refute_receive(_)
  end
end

defmodule Domo.EventListener.WakeupLight do
  use GenServer

  defstruct [:time, :days_of_week, :light_intensity, :minutes_to_fade_in, :node_id]

  def start_link(options) do
    GenServer.start_link(__MODULE__, options)
  end

  def init(options) do
    {:ok, options}
  end

  def handle_info({:event, %{event_type: "clock_update"} = event}, options) do
    [0, 1] |> Enum.map(fn(day_offset) ->
      potential_wakup_datetime = event.datetime |> Timex.add(Timex.Duration.from_days(day_offset)) |> Timex.set([hour: options.time[:hour], minute: options.time[:minute]])

      day_of_week = potential_wakup_datetime |> Timex.weekday() |> Timex.day_shortname()

      minutes_to_wakeup = potential_wakup_datetime |> Timex.diff(event.datetime, :minutes)

      cond do
        !Enum.member?(options.days_of_week, day_of_week) ->
          # wrong day of the week
          nil
        minutes_to_wakeup > options.minutes_to_fade_in ->
          # not time yet
          nil
        minutes_to_wakeup < 0 ->
          # time has passed
          nil
        true ->
          # ok, turn on the light
          intensity = options.light_intensity * (1 - minutes_to_wakeup / options.minutes_to_fade_in) |> round()
          send(options.node_id, {:command, {:basic_set, intensity}})
      end
    end)

    {:noreply, options}
  end
end

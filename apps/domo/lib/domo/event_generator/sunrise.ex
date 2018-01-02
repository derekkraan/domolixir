defmodule Domo.Sunrise do
  def start_link do
    Agent.start_link(fn -> fetch end, name: __MODULE__)
  end

  def today do
    Agent.get_and_update(__MODULE__, fn state ->
      new_state = case state |> elem(0) do
        date_today -> state
        _ -> fetch
      end
      {new_state |> elem(1), new_state}
    end)
  end

  defp fetch do
    with {:ok, response} <- HTTPoison.get("https://api.sunrise-sunset.org/json?lat=52.37&lng=4.89&formatted=0"),
    {:ok, parsed_json} <- Poison.decode(response.body) do
      {:ok, sunrise, 0} = parsed_json["results"]["sunrise"] |> DateTime.from_iso8601
      {:ok, sunset, 0} = parsed_json["results"]["sunset"] |> DateTime.from_iso8601

      { date_today, %{sunrise: sunrise, sunset: sunset} }
    end
  end

  defp date_today, do: DateTime.utc_now |> DateTime.to_date |> Date.to_iso8601
end

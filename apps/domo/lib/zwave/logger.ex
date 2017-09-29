defprotocol ZWave.Logger do
  @fallback_to_any true
  def log(data)
end

defimpl ZWave.Logger, for: ZWave.Msg do
  require Logger
  def log(msg) do
    "Sending message: #{msg |> inspect}" |> Logger.debug
    msg
  end
end

defimpl ZWave.Logger, for: ZWave.Resp do
  require Logger
  def log(resp) do
    "Received: #{resp.bytes |> inspect}" |> Logger.debug
    resp
  end
end

defimpl ZWave.Logger, for: Any do
  require Logger
  def log(any) do
    Logger.debug(any)
    any
  end
end


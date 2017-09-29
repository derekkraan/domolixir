defprotocol ZStick.Logger do
  @fallback_to_any true
  def log(data)
end

defimpl ZStick.Logger, for: ZStick.Msg do
  require Logger
  def log(msg) do
    "Sending message: #{msg |> inspect}" |> Logger.debug
    msg
  end
end

defimpl ZStick.Logger, for: ZStick.Resp do
  require Logger
  def log(resp) do
    "Received: #{resp.bytes |> inspect}" |> Logger.debug
    resp
  end
end

defimpl ZStick.Logger, for: Any do
  require Logger
  def log(any) do
    Logger.debug(any)
    any
  end
end


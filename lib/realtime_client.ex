defmodule RealtimeClient do
  use GenServer

  alias PhoenixClient.{Socket, Channel}

  def init(opts) do
    Socket.init(opts)
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name, Realtime.Socket)
    Socket.start_link(opts, name: name)
  end

  def child_spec(_opts) do
    url = Application.fetch_env!(:realtime_client, :endpoint)
    socket_opts = [url: url]

    socket_opts =
      case Application.fetch_env!(:realtime_client, :apikey) do
        nil -> socket_opts
        apikey -> Keyword.put(socket_opts, :params, %{apikey: apikey})
      end

    Socket.child_spec({socket_opts, name: Realtime.Socket})
  end

  def subscribe(topic) do
    case Channel.join(Realtime.Socket, topic) do
      {:ok, _, channel} -> {:ok, channel}
      error -> error
    end
  end
end

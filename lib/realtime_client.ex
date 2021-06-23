defmodule RealtimeClient do
  use GenServer

  alias PhoenixClient.{Socket, Channel}

  def init(opts) do
    opts = init_opts(opts)
    Socket.init(opts)
  end

  def start_link(opts) do
    name = Keyword.get(opts, :name, Realtime.Socket)
    opts = init_opts(opts)
    Socket.start_link(opts, name: name)
  end

  def child_spec(opts) do
    socket_opts = init_opts(opts)
    Socket.child_spec({socket_opts, name: Realtime.Socket})
  end

  def subscribe(topic) do
    case Channel.join(Realtime.Socket, topic) do
      {:ok, _, channel} -> {:ok, channel}
      error -> error
    end
  end

  defp init_opts(opts) do
    url =
      Keyword.get_lazy(opts, :url, fn -> Application.fetch_env!(:realtime_client, :endpoint) end)

    params =
      case Keyword.get(opts, :params, %{}) |> Map.get(:apikey) do
        nil ->
          apikey = Application.fetch_env!(:realtime_client, :apikey)
          %{apikey: apikey}

        _ ->
          opts[:params]
      end

    [url: url, params: params]
  end
end

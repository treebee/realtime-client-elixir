defmodule RealtimeClient do
  @moduledoc """
  Client library to work with [Realtime](https://github.com/supabase/realtime).

  It's mostly a wrapper around [Phoenix Client](https://github.com/mobileoverlord/phoenix_client).

  ## Getting started

  First you have to create a client Socket:

      options = [
        url: "ws://realtime-server:4000/socket/websocket",
      ]
      {:ok, socket} = RealtimeClient.socket(options)

  Once you have a connected socket, you can subscribe to topics:

      {:ok, channel} = RealtimeClient.subscribe(socket, "realtime:*")

  You can also subscribe to a specific channel (row level changes):

      {:ok, channel} = RealtimeClient.subscribe(socket, "realtime:public:users:id=eq.42")

  Consuming events is done with `handle_info` callbacks:

      alias PhoenixClient.Message

      # handle `INSERT` events
      def handle_info(%Message{event: "INSERT", payload: %{"record" => record}} = msg, state) do
          # do something with record
          {:noreply, state}
      end

      # handle `DELETE` events
      def handle_info(%Message{event: "DELETE", payload: %{"record" => record}} = msg, state) do
          IO.inspect(record, label: "DELETE")
          {:noreply, state}
      end

      # match all cases not handled above
      def handle_info(%Message{} = msg, state) do
          {:noreply, state}
      end

  ## Configuration

  Socket endpoint and parameters can also be configured:

      config :realtime_client,
        endpoint: "ws://realtime-server:4000/socket/websocket",
        apikey: "eyJhbGciOiJIUzI1MiIsInR5cCI6IkpXVCJ9.eyJJc3N1ZXIiOiJJc3N1ZXIifQ.LNcM66Tt3ejSf0fHJ-I8yh8Hgfmvh8I_CXyBIOU8S6c"

  Creating the socket can then be done with:

      {:ok, socket} = RealtimeClient.socket()


  """
  alias PhoenixClient.{Socket, Channel}

  @doc false
  def init(opts) do
    opts = init_opts(opts)
    Socket.init(opts)
  end

  @doc false
  def start_link(opts) do
    name = Keyword.get(opts, :name, Realtime.Socket)
    opts = init_opts(opts)
    Socket.start_link(opts, name: name)
  end

  @doc false
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

  @doc """
  Subscribes to a topic through given socket.
  In cases where the socket is not connected (yet), the function is
  retried (see `subscribe/4`).

    * `socket` - The name of pid of the client socket
    * `topic` - The topic to subscribe to

  """
  def subscribe(socket, topic) do
    subscribe(socket, topic, 3)
  end

  def subscribe(socket, topic, retires, error \\ nil)

  def subscribe(_socket, _topic, 0, error) do
    error
  end

  def subscribe(socket, topic, retries, _error) do
    case Channel.join(socket, topic) do
      {:ok, _, channel} ->
        {:ok, channel}

      error ->
        Process.sleep(100)
        subscribe(socket, topic, retries - 1, error)
    end
  end

  @doc """
  Creates a new client socket.

    * `opts` - The optional list of options. See below.

  ## Options

    * `url` - the url of the websocket to connect to
    * `params` - the params to send to the websocket, e.g. to pass an api key

  """
  def socket(opts \\ []) do
    init_opts(opts)
    |> Socket.start_link()
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

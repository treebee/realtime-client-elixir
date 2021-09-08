[![.github/workflows/ci.yml](https://github.com/treebee/realtime-client-elixir/actions/workflows/ci.yml/badge.svg)](https://github.com/treebee/realtime-client-elixir/actions/workflows/ci.yml) [![Coverage Status](https://coveralls.io/repos/github/treebee/realtime-client-elixir/badge.svg?branch=main)](https://coveralls.io/github/treebee/realtime-client-elixir?branch=main)

# RealtimeClient

Client for connecting to [realtime](https://github.com/supabase/realtime).
It's mostly a wrapper around [phoenix_client](https://github.com/mobileoverlord/phoenix_client).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `realtime_client` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:realtime_client, "~> 0.1.0"}
  ]
end
```

## Getting Started

First you have to create a client Socket:

```elixir
options = [
  url: "ws://realtime-server:4000/socket/websocket",
]
{:ok, socket} = RealtimeClient.socket(options)
```

Once you have a connected socket, you can subscribe to topics:

```elixir
{:ok, channel} = RealtimeClient.subscribe(socket, "realtime:*")
```

You can also subscribe to a specific channel (row level changes):

```elixir
{:ok, channel} = RealtimeClient.subscribe(socket, "realtime:public:users:id=eq.42")
```

Consuming events is done with `handle_info` callbacks:

```elixir
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
```

## Configuration

```elixir
config :realtime_client,
  endpoint: "ws://localhost:4000/socket/websocket"
  apikey: "some-JWT" # when using secure channels
```

## Using a single Socket

If you don't need to create multiple client Sockets (e.g. one per user session) but only need one for your application, you can also
start one as part of your supervision tree:

```elixir
  # application.ex
  ...

  def start(_type, _args) do
    children = [
      RealtimeAppWeb.Telemetry,
      {Phoenix.PubSub, name: RealtimeApp.PubSub},
      RealtimeAppWeb.Endpoint,

      # Add RealtimeClient to start the client Socket
      RealtimeClient,
      {RealtimeApp.Worker, "realtime:*"} # Example worker, see below
    ]

    opts = [strategy: :one_for_one, name: RealtimeApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
```

### Example Worker

```elixir
defmodule RealtimeApp.Worker do
  use GenServer

  alias PhoenixClient.Message

  def init(topic) do
    subscribe(topic)
    {:ok, %{}}
  end

  def start_link(topic) do
    GenServer.start_link(__MODULE__, topic)
  end

  def subscribe(topic) do
    send(self(), {:subscribe, topic})
  end

  def handle_info({:subscribe, topic}, state) do
    case RealtimeClient.subscribe(topic) do
      {:error, _error} ->
        Process.send_after(self(), {:subscribe, topic}, 300)
        {:noreply, state}

      {:ok, channel} ->
        {:noreply, Map.put(state, :channel, channel)}
    end
  end

  def handle_info(%Message{event: "INSERT", payload: %{"record" => record}}, state) do
    IO.inspect(record, label: "record")
    {:noreply, state}
  end
end

```

## Running Tests

There's a docker compose setup in `./docker` that can be used for development and
testing.

```bash
make start && sleep 5
make test
```

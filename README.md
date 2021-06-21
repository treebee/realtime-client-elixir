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

## Configuration

```elixir
config :realtime_client,
  endpoint: "ws://localhost:4000/socket/websocket"
```

## Starting the Client Socket

When configured correctly, you can add `RealtimeClient` to your supervision tree:

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

## Example Worker

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

defmodule RealtimeClientTest do
  use ExUnit.Case

  alias PhoenixClient.{Message, Socket}

  Application.put_env(:realtime_client, :endpoint, "ws://localhost:4000/socket/websocket")

  Application.put_env(
    :realtime_client,
    :apikey,
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJJc3N1ZXIiOiJJc3N1ZXIifQ.LNcM66Tt3ejSf0fHJ-I8yh8Hgfmvh8I_CXyBIOU8S6c"
  )

  Application.put_env(
    :realtime_client,
    Repo,
    url: "ecto://postgres:postgres@localhost/postgres",
    password: "postgres",
    database: "postgres"
  )

  defmodule Repo do
    use Ecto.Repo, otp_app: :realtime_client, adapter: Ecto.Adapters.Postgres
  end

  defmodule Todo do
    use Ecto.Schema

    schema "todos" do
      field(:user_id, :integer)
      field(:details, :string)
    end
  end

  _ =
    Ecto.Adapters.Postgres.storage_up(
      Repo.config() ++
        [password: "postgres", database: "postgres", username: "postgres"]
    )

  setup_all do
    children = [
      {Repo, [password: "postgres", database: "postgres", username: "postgres"]}
    ]

    {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

    :ok
  end

  test "Connects to Socket on start" do
    {:ok, socket} =
      RealtimeClient.start_link(
        url: "ws://localhost:4000/socket/websocket",
        apikey:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJJc3N1ZXIiOiJJc3N1ZXIifQ.LNcM66Tt3ejSf0fHJ-I8yh8Hgfmvh8I_CXyBIOU8S6c"
      )

    assert wait_for_socket(socket)
  end

  test "Can subscribe to topic" do
    start_supervised(RealtimeClient)
    wait_for_socket(Realtime.Socket)

    assert {:ok, _channel} = RealtimeClient.subscribe("realtime:*")
  end

  test "Can receive message" do
    start_supervised(RealtimeClient)
    wait_for_socket(Realtime.Socket)

    {:ok, _channel} = RealtimeClient.subscribe("realtime:*")

    todo = %Todo{user_id: 1, details: "todo"}
    {:ok, todo} = Repo.insert(todo)

    assert_receive %Message{
      event: "INSERT",
      topic: "realtime:*",
      payload: %{"table" => "todos", "record" => record}
    }

    assert String.to_integer(record["id"]) == todo.id
  end

  def wait_for_socket(_socket, n \\ 3)
  def wait_for_socket(_, 0), do: false

  def wait_for_socket(socket, n) do
    unless Socket.connected?(socket) do
      Process.sleep(100)
      wait_for_socket(socket, n - 1)
    end

    true
  end
end

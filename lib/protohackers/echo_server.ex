defmodule Protohackers.EchoServer do
  use GenServer

  require Logger

  @buffer_limit _100_kb = 1024 * 100

  @task_supervisor Protohackers.TaskSupervisor

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  defstruct ~w( listen_socket )a

  @impl true
  def init(_) do
    Logger.info("Starting EchoServer.")

    listen_options = [mode: :binary, active: false, reuseaddr: true, exit_on_close: false]

    case :gen_tcp.listen(5001, listen_options) do
      {:ok, listen_socket} ->
        state = %__MODULE__{listen_socket: listen_socket}

        {:ok, state, {:continue, :accept}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl true
  def handle_continue(:accept, %__MODULE__{listen_socket: listen_socket} = state) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        Task.Supervisor.start_child(@task_supervisor, fn -> handle_connection(socket) end)

        {:noreply, state, {:continue, :accept}}

      {:error, reason} ->
        {:stop, reason}
    end
  end

  # Helpers

  defp handle_connection(socket) do
    Logger.info("Accepting connection: #{inspect(socket)}")

    case recv_until_closed(socket, _buffer = "", _buffered_size = 0) do
      {:ok, data} ->
        Logger.info("Sending data: #{inspect(data)}")
        :gen_tcp.send(socket, data)

      {:error, reason} ->
        Logger.error("Failed to receive data: #{inspect(reason)}")
    end

    :gen_tcp.close(socket)
  end

  defp recv_until_closed(socket, buffer, buffered_size) do
    case :gen_tcp.recv(socket, 0, 10_000) do
      {:ok, data} when buffered_size + byte_size(data) > @buffer_limit ->
        {:error, :buffer_overflow}

      {:ok, data} ->
        recv_until_closed(socket, [buffer, data], buffered_size + byte_size(data))

      {:error, :closed} ->
        {:ok, buffer}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

defmodule Helpers.WSHandlerServer do
  use GenServer

  alias HighNoon.Handler

  # Client

  def start_link do
    GenServer.start_link(__MODULE__, :ok)
  end

  def send_ws_message(pid, msg) do
    GenServer.cast(pid, {:ws_message, msg})
  end

  def responses(pid) do
    GenServer.call(pid, :responses)
  end

  def messages(pid) do
    GenServer.call(pid, :messages)
  end

  # Server

  def init(_args) do
    {:ok, handler_state} = Handler.websocket_init([])
    {:ok, %{handler_responses: [], received_messages: [], handler_state: handler_state}}
  end

  def handle_cast({:ws_message, msg}, state) do
    new_state =
      case Handler.websocket_handle(msg, state.handler_state) do
        {:reply, response, new_handler_state} ->
          %{
            handler_responses: [response | state.handler_responses],
            handler_state: new_handler_state
          }

        {:ok, new_handler_state} ->
          %{state | handler_state: new_handler_state}
      end

    {:noreply, new_state}
  end

  def handle_info(msg, state) do
    new_state =
      case Handler.websocket_info(msg, state.handler_state) do
        {:reply, response, new_handler_state} ->
          %{
            handler_responses: [response | state.handler_responses],
            received_messages: [msg | state.received_messages],
            handler_state: new_handler_state
          }

        {:ok, new_handler_state} ->
          %{state | handler_state: new_handler_state}
      end

    {:noreply, new_state}
  end

  def handle_call(:responses, _from, state) do
    {:reply, state.handler_responses, state}
  end

  def handle_call(:messages, _from, state) do
    {:reply, state.received_messages, state}
  end
end

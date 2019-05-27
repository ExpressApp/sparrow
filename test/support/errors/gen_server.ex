defmodule Sparrow.Support.GenServer do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  defmodule State do
    defstruct a: 1, b: 2, c: %{d: []}
  end

  def init(_) do
    {:ok, %State{}}
  end

  def handle_info(:bad_return, _state) do
    :bad_return
  end

  def handle_info(:exit, _state) do
    exit({:bang, %{very_complex_exit_message: <<1, 2, 3>>}})
  end

  def handle_info(:throw, _state) do
    throw(:throwed)
  end

  def handle_info(:raise, _state) do
    raise ArgumentError
  end

  def handle_info(:badmatch, state) do
    1 = state.b
  end

  def handle_info(:badarg, _state) do
    send(nil, :message)
  end
end

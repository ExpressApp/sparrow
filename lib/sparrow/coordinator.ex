defmodule Sparrow.Coordinator do
  @moduledoc false

  use GenServer

  def start_link(args) do
    GenServer.start(__MODULE__, args, name: __MODULE__)
  end

  def init(_args) do
    {:ok, []}
  end

  def handle_info({Sparrow.Catcher, log, config}, state) do
    Task.Supervisor.start_child(Sparrow.TaskSupervisor, fn ->
      Sparrow.Catcher.async_log(log, config)
    end)

    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

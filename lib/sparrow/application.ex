defmodule Sparrow.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Sparrow.Coordinator, restart: :permanent},
      {Task.Supervisor, name: Sparrow.TaskSupervisor},
    ]

    attach_to_logger_handler()

    opts = [strategy: :one_for_one, name: Sparrow.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp attach_to_logger_handler do
    :logger.add_handler(Sparrow, Sparrow.Catcher, handler_config())
  end

  defp handler_config do
    :sparrow
    |> Application.get_env(:handler_config, [])
    |> Enum.into(%{})
    |> Map.put_new(:level, :error)
  end
end

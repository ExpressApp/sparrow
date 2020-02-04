defmodule Sparrow.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Sparrow.Case
    end
  end

  setup do
    Process.flag(:trap_exit, true)
    :logger.update_handler_config(Sparrow, %{notify: self()})

    on_exit(fn ->
      # FIXME waiting for Sparrow.TaskSupervisor to be done
      :timer.sleep(50)
    end)
  end
end

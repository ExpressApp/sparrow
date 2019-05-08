defmodule Sparrow.IntegrationCase do
  use ExUnit.CaseTemplate

  setup do
    Process.flag(:trap_exit, true)
    :logger.update_handler_config(Sparrow, %{notify: self()})

    on_exit(fn ->
      # FIXME waiting for Sparrow.TaskSupervisor to be done
      :timer.sleep(50)
    end)
  end
end

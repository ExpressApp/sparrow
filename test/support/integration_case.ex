defmodule Sparrow.IntegrationCase do
  use ExUnit.CaseTemplate

  setup do
    Process.flag(:trap_exit, true)
    :logger.update_handler_config(Sparrow, %{notify: self()})

    :ok
  end
end

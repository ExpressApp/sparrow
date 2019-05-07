defmodule IntegrationCase do
  use ExUnit.CaseTemplate

  import Mox

  using do
    quote do
      import Mox
    end
  end

  setup [:set_mox_from_context, :verify_on_exit!]

  setup do
    Process.flag(:trap_exit, true)
    :logger.update_handler_config(Sparrow, %{notify: self()})

    stub(Sparrow.ClientMock, :request, fn(_url, _headers, _body, _opts) ->
      {:ok, Jason.encode!(%{"id" => 42})}
    end)

    :ok
  end
end

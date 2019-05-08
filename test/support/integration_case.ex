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

    Mox.stub(Sparrow.ClientMock, :request, fn(_url, _headers, _body, _opts) ->
      {:ok, Jason.encode!(%{"id" => 42})}
    end)

    :ok
  end
end

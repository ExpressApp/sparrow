defmodule Sparrow.Case do
  use ExUnit.CaseTemplate

  import Mox

  using do
    quote do
      import Mox
      import Sparrow.Case
    end
  end

  setup [:stub_client, :set_mox_from_context, :verify_on_exit!]

  setup do
    swap_env(:client, Sparrow.ClientMock)
  end

  def stub_client(_ctx) do
    stub(Sparrow.ClientMock, :request, fn(_, _, _, _) -> {:ok, ~s[{"id":"42"}]} end)

    :ok
  end

  def appb(name) do
    if Version.compare(System.version(), "1.10.0") == :lt do
      to_string(name)
    else
      "#{name} #{Application.spec(name)[:vsn]}"
    end
  end

  def trim_lineno(term) when is_binary(term) do
    String.replace(term, ~r/\:(\d+)\:/, "")
  end

  def swap_env(key, value) do
    old_value = Application.get_env(:sparrow, key, value)
    Application.put_env(:sparrow, key, value)

    on_exit(fn -> Application.put_env(:sparrow, key, old_value) end)
  end

  def swap_handler_config(config) do
    {:ok, old_config} = :logger.get_handler_config(Sparrow)
    :ok = :logger.update_handler_config(Sparrow, Enum.into(config, %{}))

    on_exit(fn -> :ok = :logger.update_handler_config(Sparrow, old_config) end)
  end
end

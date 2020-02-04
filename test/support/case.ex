defmodule Sparrow.Case do
  use ExUnit.CaseTemplate

  import Mox

  using do
    quote do
      import Mox
      import Sparrow.Case
    end
  end

  setup [:set_mox_from_context, :verify_on_exit!]

  setup do
    old_client = Application.get_env(:sparrow, :client)
    Application.put_env(:sparrow, :client, Sparrow.ClientMock)

    on_exit(fn ->
      Application.put_env(:sparrow, :client, old_client)
    end)
  end

  def appb(name) do
    if Version.compare(System.version(), "1.10.0") == :lt do
      to_string(name)
    else
      "#{name} #{Application.spec(name)[:vsn]}"
    end
  end
end

Mox.defmock(Sparrow.ClientMock, for: Sparrow.Client.Behaviour)

defmodule Sparrow.ClientVoid do
  @behaviour Sparrow.Client.Behaviour

  def request(_, _, _, _) do
    {:ok, ~s({"id":0})}
  end
end

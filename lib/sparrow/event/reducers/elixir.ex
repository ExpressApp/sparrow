defmodule Sparrow.Event.Reducers.Elixir do
  @moduledoc false
  @behaviour Sparrow.Event.Reducer

  # skip report from Task, because it duplicates crash report
  def reduce(%{msg: {:report, %{format: ~c'** Task ~p terminating~n' ++ _, args: [_pid, _from, _fun, _args, _reason]}}}, _event) do
    :skip
  end

  def reduce(_, event) do
    event
  end
end

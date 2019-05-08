defmodule Sparrow.Event.Reducers.Erlang do
  @moduledoc false
  @behaviour Sparrow.Event.Reducer

  def reduce(%{msg: {~c'Error in process ~p with exit value:~n~p~n', [pid, reason]}}, event) do
    proc_crash(event, pid, Sparrow.format_reason(reason))
  end

  def reduce(_, event) do
    event
  end

  defp proc_crash(event, pid, {reason, stacktrace}) do
    event
    |> Sparrow.Event.put_exception(:error, reason, stacktrace)
    |> Sparrow.Event.put_stacktrace(stacktrace)
    |> Sparrow.Event.put_extra(%{pid: pid})
  end
end

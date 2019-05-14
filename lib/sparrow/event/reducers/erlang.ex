defmodule Sparrow.Event.Reducers.Erlang do
  @moduledoc false
  @behaviour Sparrow.Event.Reducer

  def reduce(%{msg: {~c'Error in process ~p with exit value:~n~p~n', [pid, reason]}}, event) do
    proc_crash(event, pid, reason)
  end

  def reduce(%{msg: {~c'Error in process ~p on node ~p with exit value:~n~p~n', [pid, _node, reason]}}, event) do
    proc_crash(event, pid, reason)
  end

  def reduce(_, event) do
    event
  end

  defp proc_crash(event, pid, reason) do
    event
    |> Sparrow.Event.put_error(reason)
    |> Sparrow.Event.put_extra(%{pid: pid})
  end
end

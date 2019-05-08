defmodule Sparrow do
  # reducer helpers

  def format_reason({maybe_exception, [_ | _] = maybe_stacktrace} = reason) do
    if Enum.all?(maybe_stacktrace, &stacktrace_entry?/1) do
      {maybe_exception, maybe_stacktrace}
    else
      {reason, []}
    end
  end

  def format_reason(reason) do
    {reason, []}
  end

  defp stacktrace_entry?({_module, _fun, _arity, _location}) do
    true
  end

  defp stacktrace_entry?({_fun, _arity, _location}) do
    true
  end

  defp stacktrace_entry?(_) do
    false
  end

  # configuration

  def dsn do
    config(:dsn)
  end

  def client do
    config(:client, Sparrow.Client)
  end

  def event_reducers do
    config(:event_reducers, [
      Sparrow.Event.Reducers.Erlang,
      Sparrow.Event.Reducers.Ranch,
    ])
  end

  def json_library do
    config(:json_library, Jason)
  end

  def tags do
    config(:tags, %{})
  end

  def server_name do
    config(:server_name)
  end

  def environment do
    config(:environment, "production")
  end

  defp config(key, default \\ nil) do
    Application.get_env(:sparrow, key, default)
  end
end

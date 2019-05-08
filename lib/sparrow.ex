defmodule Sparrow do
  @compile {:inline, current_stacktrace: 0}

  def capture(message, opts \\ []) do
    event =
      Sparrow.Event.new()
      |> Sparrow.Event.put_message(message)
      |> Sparrow.Event.put_stacktrace(Keyword.get(opts, :stacktrace, current_stacktrace()))
      |> Sparrow.Event.put_extra(Keyword.get(opts, :extra, %{}))

    Sparrow.Client.send(event)
  end

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

  def current_stacktrace do
    case Process.info(self(), :current_stacktrace) do
      {:current_stacktrace, [{Process, :info, 2, _}, {Sparrow, :capture, 2, _} | stacktrace]} -> stacktrace
      {:current_stacktrace, stacktrace} -> stacktrace
      _ -> []
    end
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

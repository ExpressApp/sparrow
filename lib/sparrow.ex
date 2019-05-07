defmodule Sparrow do
  def dsn do
    config(:dsn)
  end

  def client do
    config(:client, Sparrow.Client)
  end

  def event_reducers do
    config(:event_reducers, [
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

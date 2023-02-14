defmodule Sparrow.DSN do
  defstruct [:endpoint, :project, :public, :secret]

  def parse(val) when val in [nil, ""] do
    {:error, :dsn_empty}
  end

  def parse(%URI{scheme: scheme, host: host, userinfo: userinfo, path: "/" <> path})
      when is_binary(scheme) and is_binary(host) and is_binary(userinfo) do
    {suffix, [project]} = project(path)

    {public, secret} =
      case String.split(userinfo, ":", parts: 2) do
        [public, secret] -> {public, secret}
        [public] -> {public, nil}
      end

    {:ok,
     %__MODULE__{
       endpoint: endpoint(scheme, host, suffix) <> "/api/store/",
       project: project,
       public: public,
       secret: secret
     }}
  end

  def parse(%URI{} = uri) do
    {:error, {:dsn_invalid, uri}}
  end

  def parse(term) when is_binary(term) do
    parse(URI.parse(term))
  end

  defp endpoint(scheme, host, []) do
    scheme <> "://" <> host
  end

  defp endpoint(scheme, host, suffix) do
    scheme <> "://" <> host <> "/" <> Enum.join(suffix, "/")
  end

  defp project(path) do
    case String.split(path, "/") do
      [_] = project -> {[], project}
      [_|_] = suffix -> Enum.split(suffix, length(suffix) - 1)
    end
  end
end

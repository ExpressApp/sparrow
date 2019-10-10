defmodule Sparrow.Client.Behaviour do
  @moduledoc """
  Behaviour for your custom HTTP client implementation if you don't want to use `hackney`.
  """

  @callback request(url :: String.t, headers :: Enum.t, body, opts :: Keyword.t)
    :: {:ok, body} | {:error, term}
      when body: String.t
end

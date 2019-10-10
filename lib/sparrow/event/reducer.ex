defmodule Sparrow.Event.Reducer do
  @moduledoc """
  Behaviour for custom reducers to handle or modify catched events.
  """

  @callback reduce(:logger.log_event(), Sparrow.Event.t) :: Sparrow.Event.t
end

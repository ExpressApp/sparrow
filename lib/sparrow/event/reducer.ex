defmodule Sparrow.Event.Reducer do
  @callback reduce(:logger.log_event(), Sparrow.Event.t) :: Sparrow.Event.t
end

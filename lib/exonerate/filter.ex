defmodule Exonerate.Filter do
  @moduledoc false

  # define the append_filter callback that all filters must implement

  @callback append_filter(Exonerate.Type.json, Exonerate.Validation.t) :: Exonerate.Validation.t

  defmacro wrap(false, acc, _, _), do: acc
  defmacro wrap(true, acc, value, path) do
    quote do
      try do
        unquote(acc)
      catch
        {:max, what} ->
          Exonerate.mismatch(unquote(value), unquote(path), guard: what)
      end
    end
  end
end

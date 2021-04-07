defmodule Exonerate.Types.Absolute do
  @enforce_keys [:method]
  defstruct @enforce_keys ++ [accept: true]

  def build(method, params \\ []), do: struct(%__MODULE__{method: method}, params)

  defimpl Exonerate.Buildable do
    def build(%{accept: true, method: method}) do
      quote do
        def unquote(method)(_, _), do: :ok
      end
    end

    def build(%{accept: false, method: method}) do
      quote do
        def unquote(method)(value, path), do: {:mismatch, {path, value}}
      end
    end
  end
end

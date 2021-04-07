defmodule Exonerate.Types.List do
  @enforce_keys [:method]
  defstruct @enforce_keys

  def build(method, _), do: %__MODULE__{method: method}

  defimpl Exonerate.Buildable do
    def build(_object = %{method: method}) do
      quote do
        defp unquote(method)(list, path) when is_list(list) do
          :ok
        end
        defp unquote(method)(content, path) do
          {:mismatch, {path, content}}
        end
      end
    end
  end
end

defmodule Exonerate.Types.Absolute do
  @enforce_keys [:path]
  defstruct @enforce_keys ++ [:accept]

  def build(accept \\ true, method) do
    %__MODULE__{
      path: method,
      accept: accept
    }
  end

  defimpl Exonerate.Buildable do
    def build(%{accept: true, path: path}) do
      quote do
        def unquote(path)(_, _), do: :ok
      end
    end

    def build(spec = %{accept: false, path: path}) do
      quote do
        def unquote(path)(value, path) do
          unquote(Exonerate.Builder.mismatch(spec))
        end
      end
    end
  end
end

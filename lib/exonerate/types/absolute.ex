defmodule Exonerate.Types.Absolute do
  @enforce_keys [:path]
  defstruct @enforce_keys ++ [:accept]

  def build(accept \\ true, path) do
    %__MODULE__{
      path: path,
      accept: accept
    }
  end

  defimpl Exonerate.Buildable do
    def build(spec = %{accept: true}) do
      quote do
        def unquote(spec.path)(_, _), do: :ok
      end
    end

    def build(spec = %{accept: false}) do
      quote do
        def unquote(spec.path)(value, path) do
          Exonerate.Builder.mismatch(value, path)
        end
      end
    end
  end
end

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
    def build(schema = %{accept: true}) do
      quote do
        def unquote(schema.path)(_, _), do: :ok
      end
    end

    def build(schema = %{accept: false}) do
      quote do
        def unquote(schema.path)(value, path) do
          Exonerate.Builder.mismatch(value, path)
        end
      end
    end
  end
end

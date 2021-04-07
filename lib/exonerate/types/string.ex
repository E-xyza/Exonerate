defmodule Exonerate.Types.String do
  @enforce_keys [:method]
  @props ~w(pattern min_length max_length)a
  defstruct @enforce_keys ++ @props

  def build(method, schema), do: %__MODULE__{
    method: method,
    pattern: schema["pattern"],
    min_length: schema["minLength"],
    max_length: schema["maxLength"]}

  def props, do: @props

  defimpl Exonerate.Buildable do
    alias Exonerate.Types.String

    def build(params = %{method: method}) do
      filter_params = params
      |> Map.take(String.props())
      |> Enum.filter(&(elem(&1, 1)))
      |> Enum.to_list

      quote do
        defp unquote(method)(content, path) when not is_binary(content) do
          {:mismatch, {path, content}}
        end
        defp unquote(method)(content, path) do
          unquote(next_call(filter_params, method))
        end
        unquote_splicing(helpers(filter_params, method))
      end
    end

    defp helpers([{filter, value} | rest], method) do
      [quote do
        defp unquote(:"#{method}-#{filter}")(content, path) do
          if unquote(filter_condition(filter, value)) do
            unquote(next_call(rest, method))
          else
            {:mismatch, {path, content}}
          end
        end
      end | helpers(rest, method)]
    end
    defp helpers([], _), do: []

    defp next_call([], _), do: :ok
    defp next_call([{filter, _}| _], method) do
      quote do
        unquote(:"#{method}-#{filter}")(content, path)
      end
    end

    defp filter_condition(:pattern, pattern) do
      quote do content =~ sigil_r(<<unquote(pattern)>>, []) end
    end

    defp filter_condition(:min_length, length) do
      quote do String.length(content) >= unquote(length) end
    end

    defp filter_condition(:max_length, length) do
      quote do String.length(content) <= unquote(length) end
    end
  end
end

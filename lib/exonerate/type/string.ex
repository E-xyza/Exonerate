defmodule Exonerate.Type.String do
  @moduledoc false

  # boilerplate!!
  @behaviour Exonerate.Type
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  defstruct [:context, :format_binary, pipeline: [], filters: []]
  @type t :: %__MODULE__{}

  alias Exonerate.Filter
  alias Exonerate.Tools
  alias Exonerate.Type
  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  @validator_filters ~w(minLength maxLength format pattern)
  @validator_modules Map.new(@validator_filters, &{&1, Filter.from_string(&1)})

  @impl true
  @spec parse(Validator.t(), Type.json()) :: t

  # draft <= 7 refs inhibit type-based analysis
  def parse(validator = %{draft: draft}, %{"$ref" => _}) when draft in ~w(4 6 7) do
    %__MODULE__{context: validator}
  end

  def parse(validator, schema) do
    %__MODULE__{context: validator, format_binary: format_binary(schema)}
    |> Tools.collect(@validator_filters, fn
      artifact, filter when is_map_key(schema, filter) ->
        Filter.parse(artifact, @validator_modules[filter], schema)

      artifact, _ ->
        artifact
    end)
  end

  defp format_binary(%{"format" => "binary"}), do: true
  defp format_binary(_), do: false

  @impl true
  @spec compile(t) :: Macro.t()
  def compile(artifact = %{format_binary: true}) do
    combining =
      Validator.combining(
        artifact.context,
        quote do
          string
        end,
        quote do
          path
        end
      )

    quote do
      defp unquote(fun(artifact, []))(string, path) when is_binary(string) do
        Exonerate.pipeline(string, path, unquote(artifact.pipeline))
        unquote_splicing(combining)
      end
    end
  end

  def compile(artifact) do
    combining =
      Validator.combining(
        artifact.context,
        quote do
          string
        end,
        quote do
          path
        end
      )

    quote do
      defp unquote(fun(artifact, []))(string, path) when is_binary(string) do
        if String.valid?(string) do
          Exonerate.pipeline(string, path, unquote(artifact.pipeline))
          unquote_splicing(combining)
        else
          Exonerate.mismatch(string, path)
        end
      end
    end
  end
end

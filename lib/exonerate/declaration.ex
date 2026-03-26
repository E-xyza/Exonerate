defmodule Exonerate.Declaration do
  @moduledoc """
  Represents a function declaration for the two-phase compilation system.

  This struct is used during the declaration collection phase to track all
  functions that need to be generated, their return types, and dependencies
  between functions. This allows consistent function naming and type inference
  across the entire schema.

  ## Fields

  - `:name` - The function name as an atom
  - `:resource` - The resource URI (String.t())
  - `:pointer` - The JSON pointer (JsonPtr.t())
  - `:opts` - Compilation options (keyword or CompilationContext.t())
  - `:return_type` - Expected return type (:ok | :ok_mapset | :ok_integer | :error | :unknown)
  - `:dependencies` - List of function names this function calls
  - `:degeneracy` - Whether the schema is always true, always false, or unknown (:ok | :error | :unknown)
  """

  @type return_type :: :ok | :ok_mapset | :ok_integer | :error | :unknown

  @type t :: %__MODULE__{
          name: atom | nil,
          resource: String.t() | nil,
          pointer: JsonPtr.t() | nil,
          opts: keyword | Exonerate.CompilationContext.t() | nil,
          return_type: return_type | nil,
          dependencies: [atom] | nil,
          degeneracy: :ok | :error | :unknown | nil
        }

  defstruct [
    :name,
    :resource,
    :pointer,
    :opts,
    :return_type,
    :dependencies,
    :degeneracy
  ]

  @doc """
  Creates a new declaration from resource, pointer, and options/context.
  """
  @spec new(String.t(), JsonPtr.t(), keyword | Exonerate.CompilationContext.t()) :: t()
  def new(resource, pointer, ctx_or_opts) do
    name = Exonerate.Tools.call(resource, pointer, ctx_or_opts)

    %__MODULE__{
      name: name,
      resource: resource,
      pointer: pointer,
      opts: normalize_opts(ctx_or_opts),
      return_type: nil,
      dependencies: [],
      degeneracy: :unknown
    }
  end

  defp normalize_opts(%Exonerate.CompilationContext{} = ctx) do
    Exonerate.CompilationContext.to_opts(ctx)
  end

  defp normalize_opts(opts) when is_list(opts), do: opts

  @doc """
  Determines the return type based on tracking mode.
  """
  @spec infer_return_type(t()) :: return_type
  def infer_return_type(%__MODULE__{opts: opts}) when is_list(opts) do
    case opts[:tracked] do
      :object -> :ok_mapset
      :array -> :ok_integer
      nil -> :ok
    end
  end

  def infer_return_type(%__MODULE__{opts: %Exonerate.CompilationContext{tracked: tracked}}) do
    case tracked do
      :object -> :ok_mapset
      :array -> :ok_integer
      nil -> :ok
    end
  end

  @doc """
  Sets the degeneracy status and updates the return type accordingly.
  """
  @spec with_degeneracy(t(), :ok | :error | :unknown) :: t()
  def with_degeneracy(%__MODULE__{} = decl, degeneracy) do
    return_type =
      case degeneracy do
        :ok -> infer_return_type(decl)
        :error -> :error
        :unknown -> :unknown
      end

    %{decl | degeneracy: degeneracy, return_type: return_type}
  end

  @doc """
  Adds a dependency to this declaration.
  """
  @spec add_dependency(t(), atom) :: t()
  def add_dependency(%__MODULE__{dependencies: deps} = decl, dep_name) do
    %{decl | dependencies: [dep_name | deps]}
  end
end

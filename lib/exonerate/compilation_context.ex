defmodule Exonerate.CompilationContext do
  @moduledoc """
  A struct representing compilation context for JSON Schema validation.

  This struct replaces the keyword options pattern used throughout the codebase,
  providing typed, predictable option passing for the compilation pipeline.

  ## Fields

  - `:resource` - Current resource URI (String.t())
  - `:pointer` - Current JSON pointer (JsonPtr.t())
  - `:caller` - Caller environment (Macro.Env.t())
  - `:only` - Type constraints for combining schemas ([String.t()] | nil)
  - `:tracked` - Tracking mode for unevaluated properties/items (:object | :array | nil)
  - `:seen` - Seen property tracking (MapSet.t() | nil)
  - `:entrypoint` - Original entrypoint pointer (JsonPtr.t())
  - `:dump` - Debug dump mode (boolean)
  - `:decoders` - Decoder configuration (list)
  - `:encoding` - Encoding type (String.t())
  - `:draft` - JSON Schema draft version (atom)
  - `:format` - Format validation mode (atom | keyword | boolean)
  """

  @type t :: %__MODULE__{
          resource: String.t() | nil,
          pointer: JsonPtr.t() | nil,
          caller: Macro.Env.t() | nil,
          only: [String.t()] | nil,
          tracked: :object | :array | nil,
          seen: MapSet.t() | nil,
          entrypoint: JsonPtr.t() | nil,
          dump: boolean | nil,
          decoders: list | nil,
          encoding: String.t() | nil,
          draft: atom | nil,
          format: atom | keyword | boolean | nil
        }

  defstruct [
    :resource,
    :pointer,
    :caller,
    :only,
    :tracked,
    :seen,
    :entrypoint,
    :dump,
    :decoders,
    :encoding,
    :draft,
    :format
  ]

  @doc """
  Creates a new CompilationContext from keyword options.

  This function provides backward compatibility with existing keyword-based APIs.
  """
  @spec from_opts(keyword) :: t()
  def from_opts(opts) when is_list(opts) do
    %__MODULE__{
      resource: Keyword.get(opts, :resource),
      pointer: Keyword.get(opts, :pointer),
      caller: Keyword.get(opts, :caller),
      only: normalize_only(Keyword.get(opts, :only)),
      tracked: Keyword.get(opts, :tracked),
      seen: Keyword.get(opts, :seen),
      entrypoint: Keyword.get(opts, :entrypoint),
      dump: Keyword.get(opts, :dump),
      decoders: Keyword.get(opts, :decoders),
      encoding: Keyword.get(opts, :encoding),
      draft: Keyword.get(opts, :draft),
      format: Keyword.get(opts, :format)
    }
  end

  @doc """
  Converts a CompilationContext to keyword options.

  This function provides backward compatibility with existing keyword-based APIs.
  """
  @spec to_opts(t()) :: keyword
  def to_opts(%__MODULE__{} = ctx) do
    ctx
    |> Map.from_struct()
    |> Enum.reject(fn {_k, v} -> is_nil(v) end)
    |> Keyword.new()
  end

  @doc """
  Merges keyword options into an existing CompilationContext.
  """
  @spec merge(t(), keyword) :: t()
  def merge(%__MODULE__{} = ctx, opts) when is_list(opts) do
    opts_map =
      opts
      |> Enum.reject(fn {_k, v} -> is_nil(v) end)
      |> Map.new()
      |> Map.update(:only, nil, &normalize_only/1)

    struct(ctx, opts_map)
  end

  @doc """
  Scrubs combining-specific options from the context.

  The following fields are cleared:
  - :only
  - :tracked
  - :seen
  """
  @spec scrub(t()) :: t()
  def scrub(%__MODULE__{} = ctx) do
    %{ctx | only: nil, tracked: nil, seen: nil}
  end

  @doc """
  Scrubs combining-specific options from keyword opts.

  For backward compatibility with existing code.
  """
  @spec scrub_opts(keyword) :: keyword
  def scrub_opts(opts) when is_list(opts) do
    Keyword.drop(opts, ~w(only tracked seen)a)
  end

  @doc """
  Updates the type constraint (:only) by intersecting with new types.

  This accumulates type restrictions through combining schemas.
  """
  @spec constrain_types(t(), [String.t()] | String.t()) :: t()
  def constrain_types(%__MODULE__{only: nil} = ctx, types) do
    %{ctx | only: List.wrap(types)}
  end

  def constrain_types(%__MODULE__{only: existing} = ctx, types) do
    existing_set = MapSet.new(existing)
    new_set = types |> List.wrap() |> MapSet.new()
    intersection = MapSet.intersection(existing_set, new_set) |> MapSet.to_list()
    %{ctx | only: intersection}
  end

  @doc """
  Sets the tracked mode for the context.
  """
  @spec with_tracked(t(), :object | :array | nil) :: t()
  def with_tracked(%__MODULE__{} = ctx, tracked) do
    %{ctx | tracked: tracked}
  end

  @doc """
  Returns the type constraints as a list, or a default list if not set.
  """
  @spec get_only(t(), [String.t()]) :: [String.t()]
  def get_only(%__MODULE__{only: nil}, default), do: default
  def get_only(%__MODULE__{only: only}, _default), do: only

  # Normalizes :only to always be a list or nil
  defp normalize_only(nil), do: nil
  defp normalize_only(types) when is_list(types), do: types
  defp normalize_only(type) when is_binary(type), do: [type]
end

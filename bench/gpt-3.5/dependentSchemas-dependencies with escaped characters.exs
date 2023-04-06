defmodule :"dependentSchemas-dependencies with escaped characters-gpt-3.5" do
  def validate(object) when is_map(object), do: :ok
  def validate(_), do: :error

  def validate(["foo\tbar" | _] = schemas, object) when is_map(object) do
    if Map.size(object) < 4 do
      {:error, "Object should have at least 4 properties"}
    else
      deps = process_dependencies(schemas, object)
      do_validate(deps, object)
    end
  end

  def validate([schema | _] = schemas, object) do
    deps = process_dependencies(schemas, object)
    do_validate(deps, object)
  end

  @spec process_dependencies([binary()], map()) :: %{binary() => :ok | :error}
  def process_dependencies([], _), do: %{}
  def process_dependencies([name | rest], object) do
    dep = Map.get(object, name)
    deps = process_dependencies(rest, object)
    Map.put(deps, name, if dep != nil, do: :ok, else: :error)
  end

  @spec do_validate(%{binary() => :ok | :error}, map()) :: :ok | :error
  def do_validate(_deps, _object) when not is_map(_object), do: :error
  def do_validate(deps, object) do
    case Map.get(deps, "foo'bar") do
      :ok ->
        case Map.get(object, "foo\"bar") do
          nil -> {:error, "Missing required property: foo\"bar"}
          _ -> :ok
        end
      _ ->
        :ok
    end
  end
end

defmodule :"escaped pointer ref-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate(%{"$defs" => defs, "properties" => props}) when is_map(defs) and is_map(props) do
    defs_valid = defs |> Enum.map(&match_def(&1)) |> Enum.all?(&(&1 == :ok))
    props_valid = props |> Enum.map(&match_prop(&1, defs)) |> Enum.all?(&(&1 == :ok))

    if defs_valid and props_valid do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end

  def match_def({k, v}) when is_atom(k) and is_map(v) do
    case v["type"] do
      "integer" -> :ok
      _ -> :error
    end
  end

  def match_def(_) do
    :error
  end

  def match_prop({k, %{"$ref" => ref}}, defs) when is_atom(k) and is_binary(ref) do
    case resolve_ref(ref, defs) do
      :ok -> :ok
      _ -> :error
    end
  end

  def match_prop({k, _}, _) do
    :error
  end

  def resolve_ref(ref, defs) when is_binary(ref) do
    case Regex.run(~r/^#\/(\$defs)?\/(\w+[\w\/\%\~]*)$/, ref) do
      [[_, _, path]] ->
        path
        |> String.split("~/")
        |> Enum.reduce_while(defs, fn name, map ->
          map[key_to_atom(name)]
          |> case do
            nil -> {:halt, :error}
            v -> {:cont, v}
          end
        end)
        |> case do
          %{"type" => "integer"} -> :ok
          _ -> :error
        end

      _ ->
        :error
    end
  end

  def resolve_ref(_, _) do
    :error
  end

  def key_to_atom(key) do
    key
    |> String.replace("%", "%25")
    |> String.replace("/", "~1")
    |> String.replace("~", "~0")
    |> String.to_atom()
  end
end
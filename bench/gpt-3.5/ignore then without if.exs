defmodule :"ignore then without if-gpt-3.5" do
  def validate(value) do
    case match?(value, %{"then" => %{"const" => 0}}) do
      true -> :ok
      false -> :error
    end
  end

  def match?(value, pattern) do
    match?(value, pattern, [])
  end

  def match?(_value, _pattern, _path) when is_list(_value) or is_map(_value) do
    false
  end

  def match?(value, %{key => pattern} = object, path) when is_map(value) do
    if Map.has_key?(value, key) do
      new_path = [key | path]
      match?(Map.get(value, key), pattern, new_path)
    else
      false
    end
  end

  def match?(value, pattern, _path) do
    value === pattern
  end
end

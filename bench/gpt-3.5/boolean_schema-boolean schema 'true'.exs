defmodule :"boolean_schema-boolean schema 'true'-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate([_ | _]) do
    :ok
  end

  def validate(nil) do
    :ok
  end

  def validate(true) do
    :ok
  end

  def validate(false) do
    :ok
  end

  def validate(number) when is_number(number) do
    :ok
  end

  def validate(string) when is_binary(string) do
    :ok
  end

  def validate({"type", "object"}) do
    fn
      object when is_map(object) -> :ok
      _ -> :error
    end
  end

  def validate({"type", "array"}) do
    fn
      list when is_list(list) -> :ok
      _ -> :error
    end
  end

  def validate(_) do
    :error
  end
end

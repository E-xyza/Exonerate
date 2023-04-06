defmodule :"default-invalid string value for default-gpt-3.5" do
  def validate(%{
        "properties" => %{
          "bar" => %{"default" => default, "minLength" => min_length, "type" => type}
        }
      })
      when is_binary(default) and is_integer(min_length) and type == "string" do
    :ok
  end

  def validate(_) do
    :error
  end
end
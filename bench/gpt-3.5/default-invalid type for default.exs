defmodule :"default-invalid type for default-gpt-3.5" do
  def validate(
        %{"properties" => %{"foo" => %{"default" => default, "type" => "integer"}}} = object
      )
      when is_map(object) and is_list(default) and Enum.all?(default, &is_integer/1) do
    :ok
  end

  def validate(_) do
    :error
  end
end
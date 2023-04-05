defmodule :"allOf with boolean schemas, some false-gpt-3.5" do
  def validate(%{"allOf" => all_of}) do
    if Enum.all?(all_of, & &1) do
      :ok
    else
      :error
    end
  end

  def validate(%{"type" => "object"} = object) do
    if is_map(object) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end

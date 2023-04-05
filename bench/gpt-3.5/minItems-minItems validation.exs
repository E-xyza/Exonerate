defmodule :"minItems validation-gpt-3.5" do
  def validate(%{type: "object"} = object) do
    if is_map(object) do
      :ok
    else
      :error
    end
  end

  def validate(%{minItems: num}) do
    if num > 0 do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end

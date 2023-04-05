defmodule :"exclusiveMinimum validation-gpt-3.5" do
  def validate(value) do
    if is_number(value) and value > 1.1 do
      :ok
    else
      :error
    end
  end
end
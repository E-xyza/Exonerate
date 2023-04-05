defmodule :"minItems validation-gpt-3.5" do
  def validate(data) when is_list(data) and length(data) >= 1 do
    :ok
  end

  def validate(_) do
    :error
  end
end
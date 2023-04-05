defmodule :"maxItems validation-gpt-3.5" do
  def validate(object) when is_list(object) and length(object) <= 2 do
    :ok
  end

  def validate(_) do
    :error
  end
end
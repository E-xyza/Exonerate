defmodule :"maximum validation with unsigned integer-gpt-3.5" do
  def validate(object)
      when is_map(object) and is_integer(object["maximum"]) and object["maximum"] >= 0 do
    :ok
  end

  def validate(_) do
    :error
  end
end
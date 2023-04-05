defmodule :"maximum validation with unsigned integer-gpt-3.5" do
  def validate(%{"maximum" => max} = json) when is_number(max) do
    if json["value"] <= max do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end

defmodule :"validation of IDN e-mail addresses-gpt-3.5" do
  def validate(object)
      when is_binary(object) and String.match?(object, ~r/@\p{L}+(\.\p{L}+)*\p{Pd}*\p{L}+/u) do
    :ok
  end

  def validate(_) do
    :error
  end
end
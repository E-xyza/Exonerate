defmodule :"format-validation of UUIDs-gpt-3.5" do
  def validate(object)
      when is_binary(object) and
             Regex.match?(
               ~r/\A#{Regex.escape(object)}\z/,
               ~r/\A[a-f0-9]{8}(-[a-f0-9]{4}){4}[a-f0-9]{8}\z/
             ) do
    :ok
  end

  def validate(_) do
    :error
  end
end
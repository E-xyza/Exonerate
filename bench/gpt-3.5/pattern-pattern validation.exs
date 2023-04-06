defmodule :"pattern-pattern validation-gpt-3.5" do
  
defmodule :"pattern-pattern validation" do
  def validate(%{"pattern" => pattern} = object) when is_binary(pattern),
    do: Regex.match?(~r/#{pattern}/, to_string(object)) ? :ok : :error
  def validate(_), do: :error
end

end

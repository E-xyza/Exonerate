defmodule :"validation of URI templates-gpt-3.5" do
  def validate(object) when is_binary(object) and String.match?(object, ~r{\A\{([^\}]*)\}\z}) do
    :ok
  end

  def validate(_) do
    :error
  end
end
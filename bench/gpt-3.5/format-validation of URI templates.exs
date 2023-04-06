defmodule :"format-validation of URI templates-gpt-3.5" do
  def validate(uri_template)
      when is_binary(uri_template) and Regex.match?(~r/{.+}/, uri_template) do
    :ok
  end

  def validate(_) do
    :error
  end
end
defmodule :"format-validation of URI templates-gpt-3.5" do
  def validate(%{"format" => "uri-template"} = decoded_json) do
    if is_map(decoded_json) do
      :ok
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end

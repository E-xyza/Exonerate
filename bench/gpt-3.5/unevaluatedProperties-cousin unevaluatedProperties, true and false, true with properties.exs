defmodule :"unevaluatedProperties-cousin unevaluatedProperties, true and false, true with properties-gpt-3.5" do
  def validate(%{"foo" => _} = object) do
    %{valid: true, errors: []} =
      MapSchema.validate(object, %{
        type: "object",
        properties: %{foo: %{type: "string"}},
        unevaluatedProperties: true
      })

    :ok
  rescue
    _ -> :error
  end

  def validate(_) do
    :error
  end
end
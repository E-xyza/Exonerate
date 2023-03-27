defmodule Benchmark.GPT do

  @openapi_url "https://api.openai.com/v1/chat/completions"

  def fetch_schema_code!(schema, opts \\ []) do
    model = Keyword.get(opts, :model, "gpt-3.5-turbo")
    api_key = System.fetch_env!("CHATGPT_SECRET_KEY")
    payload = Jason.encode!(%{
      model: model,
      messages: [%{role: :user, content: """
      Hi, ChatGPT! I would love your help writing an Elixir public function `validate/1`, which takes
      one parameter, which is a decoded JSON value.  The function should return :ok if the following
      jsonschema validates, and an error if it does not:

      ```
      #{schema}
      ```

      The function should NOT store or parse the schema, it should translate the instructions in the schema directly as
      elixir code.  For example:

      ```
      {"type": "object"}
      ```

      should emit the following code:

      ```
      def validate(object) when is_map(object), do: :ok
      def validate(_), do: :error
      ```

      DO NOT STORE THE SCHEMA or EXAMINE THE SCHEMA anywhere in the code.  There should not be any
      `schema` variables anywhere in the code, please do not provide the surrounding module
      definition.

      Thank you!
      """}]
    })

    %{status: 200, body: body} = Req.post!(
      @openapi_url, headers: [content_type: "application/json", authorization: "Bearer #{api_key}"], body: payload,
      receive_timeout: :infinity)

    body
    |> get_in(["choices", Access.at!(0), "message", "content"])
    |> String.split("```")
    |> Enum.at(1)
    |> IO.puts
  end
end

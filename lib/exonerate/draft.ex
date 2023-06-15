defmodule Exonerate.Draft do
  @moduledoc false

  @all_drafts ~w(4 6 7 2019-09 2020-12)

  @spec opts_before?(String.t(), keyword) :: boolean
  def opts_before?(date, opts) do
    opts
    |> Keyword.get(:draft, "2020-12")
    |> do_before?(date)
  end

  defp do_before?("4", "6"), do: true
  defp do_before?(x, "7") when x in ~w(4 6), do: true
  defp do_before?(x, "2019-09") when x in ~w(4 6 7), do: true
  defp do_before?(x, "2020-12") when x in ~w(4 6 7 2019-09), do: true
  defp do_before?(x, y) when x in @all_drafts and y in @all_drafts, do: false

  @schemas %{
    "https://json-schema.org/draft/2020-12/schema" => "2020-12",
    "https://json-schema.org/draft/2019-09/schema" => "2019-09",
    "http://json-schema.org/draft-07/schema#" => "7",
    "http://json-schema.org/draft-06/schema#" => "6",
    "http://json-schema.org/draft-04/schema#" => "4"
  }

  def set_opts(opts, schema = %{"$schema" => tag}) do
    if draft = Map.get(@schemas, tag) do
      Keyword.put(opts, :draft, draft)
    else
      set_opts(opts, Map.delete(schema, "$schema"))
    end
  end

  def set_opts(opts, schema) do
    # if it's not at the root, check the entrypoint.
    if old_entrypoint = opts[:entrypoint] do
      json_pointer = JsonPtr.from_path(old_entrypoint)

      opts
      |> Keyword.delete(:entrypoint)
      |> set_opts(JsonPtr.resolve_json!(schema, json_pointer))
      |> Keyword.put(:entrypoint, old_entrypoint)
    else
      # go with what we declared in the opts, or default to 2020-12
      Keyword.put_new(opts, :draft, "2020-12")
    end
  end
end

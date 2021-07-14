defmodule Exonerate.Filter.Format do
  @behaviour Exonerate.Filter
  @derive Exonerate.Compiler
  @derive {Inspect, except: [:context]}

  alias Exonerate.Registry
  alias Exonerate.Validator

  import Validator, only: [fun: 2]

  defstruct [:context, :fun]

  @defaults %{
    "date-time" => {:__datetime_validate, :datetime, [:any]},
    "date" => {:__date_validate, :date, []},
    "time" => {:__time_validate, :time, []},
    "ipv4" => {:__ipv4_validate, :ipv4, []},
    "ipv6" => {:__ipv6_validate, :ipv6, []},
    "uuid" => {:__uuid_validate, :uuid, [:any]},
    "uri-template" => {:__annotate, nil, []},
    "json-pointer" => {:__annotate, nil, []},
    "relative-json-pointer" => {:__annotate, nil, []},
    "regex" => {:__annotate, nil, []},
    "uri" => {:__annotate, nil, []},
    "uri-reference" => {:__annotate, nil, []},
    "iri" => {:__annotate, nil, []},
    "iri-reference" => {:__annotate, nil, []},
    "hostname" => {:__annotate, nil, []},
    "idn-hostname" => {:__annotate, nil, []},
    "email" => {:__annotate, nil, []},
    "idn-email" => {:__annotate, nil, []},
  }

  # pass over the binary format, which gets special treatment elsewhere.
  def parse(artifact, %{"format" => "binary"}), do: artifact
  def parse(artifact = %Exonerate.Type.String{}, %{"format" => format}) do
    fun = Map.get(@defaults, format, {:__annotate, nil, []})

    %{artifact |
      pipeline: [fun(artifact, "format") | artifact.pipeline],
      filters: [%__MODULE__{context: artifact.context, fun: fun} | artifact.filters]}
  end

  def compile(filter = %__MODULE__{fun: {function, builtin, args}}) when is_atom(function) do
    builtin_fn = List.wrap(if Registry.format_needed(function) do
      builtins(builtin)
    end)

    call = {function, [], [quote do string end | args]}

    {[],[quote do
      defp unquote(fun(filter, "format"))(string, path) do
        unless unquote(call) do
          Exonerate.mismatch(string, path)
        end
        string
      end
      unquote_splicing(builtin_fn)
    end]}
  end

  defp builtins(:datetime) do
    quote do
      defp __datetime_validate(string, :any), do: __datetime_validate(string, :utc) or __datetime_validate(string, :naive)
      defp __datetime_validate(string, :utc), do: match?({:ok, _, _}, Elixir.DateTime.from_iso8601(string))
      defp __datetime_validate(string, :naive), do: match?({:ok, _}, NaiveDateTime.from_iso8601(string))
    end
  end

  defp builtins(:date) do
    quote do
      defp __date_validate(string), do: match?({:ok, _}, Elixir.Date.from_iso8601(string))
    end
  end

  defp builtins(:time) do
    quote do
      defp __time_validate(string), do: match?({:ok, _}, Elixir.Time.from_iso8601(string))
    end
  end

  defp builtins(:uuid) do
    quote do
      defp __uuid_validate(string, :any), do: match?({:ok?, _}, :inet.parse_ipv4strict_address(String.to_charlist(string)))
    end
  end

  defp builtins(:ipv4) do
    quote do
      defp __ipv4_validate(string), do: match?({:ok?, _}, :inet.parse_ipv4strict_address(String.to_charlist(string)))
    end
  end

  defp builtins(:ipv6) do
    quote do
      def __ipv6_validate(string), do: match?({:ok?, _}, :inet.parse_ipv6strict_address(String.to_charlist(string)))
    end
  end

  defp builtins(nil) do
    quote do
      def __annotate(_), do: true
    end
  end
end

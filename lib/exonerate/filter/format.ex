defmodule Exonerate.Filter.Format do
  @moduledoc false

  @defaults %{
    "date-time" => {:__datetime_validate, :datetime, [:any]},
    "date" => {:__date_validate, :date, []},
    "time" => {:__time_validate, :time, []},
    "ipv4" => {:__ipv4_validate, :ipv4, []},
    "ipv6" => {:__ipv6_validate, :ipv6, []},
    "uuid" => {:__annotate, nil, []},
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
    "idn-email" => {:__annotate, nil, []}
  }

  def format, do: @defaults
end

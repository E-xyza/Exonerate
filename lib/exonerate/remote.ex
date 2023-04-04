defmodule Exonerate.Remote do
  @moduledoc """
  Adapter for fetching remote content.

  Use the `fetch_remote!/2` for creating your own adapters if the default
  adapter is inappropriate for your use case.

  Note that this module also contains overall logic for managing remote
  schemas.
  """

  alias Exonerate.Cache
  alias Exonerate.Tools
  alias Exonerate.Schema

  @spec ensure_resource_loaded!(URI.t(), Env.t(), keyword) :: URI.t()
  @doc false
  # Ensures the resource represented by the URI exists in the cache.
  #
  # If it doesn't exist in the cache, then attempt to fetch it from Exonerate's
  # priv directory (or app pointed to by options).
  #
  # If it doesn't exist there, prompt the user that the remote json will be
  # loaded. If the user picks yes, then download it.
  #
  # ### Options
  #
  # - `:cache_app`: specifies the otp app whose priv directory cached remote
  #  JSONs are stored.
  #
  #  Defaults to `:exonerate`.
  #
  # - `:cache_path`: specifies the subdirectory of priv where cached remote
  #  JSONs are stored.
  #
  #  Defaults to `/`.
  #
  # - `:remote_fetch_adapter`: specifies the module that exposes the public
  #  function `fetch_remote!/2`.  This function should take a URI and
  #  the options passed to `ensure_resource_loaded!/2` and raise if failures
  #  occur, or return :ok if it succeeds.
  #
  #  Defaults to `#{__MODULE__}`.

  def ensure_resource_loaded!(uri, caller, opts) do
    if Cache.has_schema?(caller.module, Tools.uri_to_resource(uri)) do
      :ok
    else
      load_cache(caller, uri, opts)
    end

    uri
  end

  defp load_cache(_, uri = %{scheme: "function"}, _) do
    raise "function resources can't loaded, (tried to load #{uri})"
  end

  defp load_cache(caller, uri, opts) do
    remote_fetch_adapter = Keyword.get(opts, :remote_fetch_adapter, __MODULE__)
    resource = Tools.uri_to_resource(uri)

    case File.read(path_for(uri, opts)) do
      {:ok, binary} ->
        # TODO: support YAML here.
        Schema.ingest(binary, caller, resource, opts)

      {:error, :enoent} ->
        proxied_uri = maybe_proxy(uri, opts)
        guard_fetch!(proxied_uri, opts)
        ensure_priv_directory!(opts)

        {body, content_type} = remote_fetch_adapter.fetch_remote!(proxied_uri, opts)

        content_type = content_type || Tools.content_type_from_extension(proxied_uri, opts)

        opts = Keyword.put(opts, :content_type, content_type)

        if Keyword.get(opts, :cache, true) do
          uri
          |> path_for(opts)
          |> File.write!(body)

          load_cache(caller, resource, opts)
        else
          Schema.ingest(body, caller, resource, opts)
        end
    end

    :ok
  end

  defp guard_fetch!(resource, opts) do
    unless opts[:force_remote] do
      response =
        IO.gets(
          IO.ANSI.yellow() <>
            "Exonerate would like to fetch a schema from #{resource}" <>
            IO.ANSI.reset() <> "\nOk? (y/n) "
        )

      case response do
        <<yes, _::binary>> when yes in ~C'Yy' ->
          :ok

        _ ->
          raise IO.ANSI.red() <>
                  "fetch rejected for online content #{resource}" <> IO.ANSI.reset()
      end
    end
  end

  @spec fetch_remote!(URI.t(), keyword) ::
          {encoded_json :: String.t(), content_type :: String.t() | nil}
  @doc """
  uses the `Req` library to fetch remote content.

  Note that this function fails if the remote resource does not return 200, and
  raises for any connection errors.
  """
  def fetch_remote!(resource, _opts) do
    Application.ensure_all_started(:req)

    %{status: 200, body: body, headers: headers} =
      resource
      |> Map.put(:fragment, nil)
      |> to_string
      |> Req.get!(decode_body: false)

    content_type =
      if List.keyfind(headers, "content-type", 0) do
        List.keyfind(headers, "content-type", 0)
        |> elem(1)
        |> String.split(";")
        |> List.first()
      end

    {body, content_type}
  end

  # utilities

  defp maybe_proxy(uri, opts) do
    if proxy_mapping = opts[:proxy] do
      proxy_mapping
      |> Enum.reduce_while(
        to_string(uri),
        fn {from, to}, uri_string ->
          if String.starts_with?(uri_string, from) do
            {:halt, String.replace_prefix(uri_string, from, to)}
          else
            {:cont, uri_string}
          end
        end
      )
      |> URI.parse()
    else
      uri
    end
  end

  defp priv_dir(opts) do
    opts
    |> Keyword.get(:cache_app, :exonerate)
    |> :code.priv_dir()
  end

  defp path_for(uri, opts) do
    priv_path = Keyword.get(opts, :cache_path, "/")

    file_name =
      uri
      |> Map.put(:fragment, nil)
      |> to_string()
      |> URI.encode_www_form()

    opts
    |> priv_dir
    |> Path.join(priv_path)
    |> Path.join(file_name)
  end

  defp ensure_priv_directory!(opts) do
    priv_dir = priv_dir(opts)
    if File.dir?(priv_dir), do: :ok, else: File.mkdir_p!(priv_dir)
  end
end

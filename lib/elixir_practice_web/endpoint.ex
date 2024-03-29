defmodule ElixirPracticeWeb.Endpoint do
  use Sentry.PlugCapture
  use Phoenix.Endpoint, otp_app: :elixir_practice

  alias Plug.Conn

  @plug_ssl Plug.SSL.init(rewrite_on: [:x_forwarded_proto], subdomains: true)

  socket("/socket", ElixirPracticeWeb.Socket)
  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: {ElixirPracticeWeb.Session, :config, []}]])

  plug(ElixirPracticeWeb.Plugs.Security)
  plug(:ping)
  plug(:canonical_host)
  plug(:force_ssl)
  plug(:cors)
  plug(:basic_auth)

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(Plug.Static,
    at: "/",
    from: :elixir_practice,
    gzip: true,
    only: ~w(assets fonts images favicon.ico robots.txt)
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)

    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
    plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :elixir_practice)
  end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Sentry.PlugContext,
    body_scrubber: {ElixirPractice.Errors.Sentry, :scrub_params},
    remote_address_reader: {ElixirPractice.Errors.Sentry, :scrubbed_remote_address}
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(ElixirPracticeHealth.Router)
  plug(ElixirPracticeGraphQL.Router)
  plug(:halt_if_sent)
  plug(ElixirPracticeWeb.Router)

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = Application.get_env(:elixir_practice, __MODULE__)[:http][:port] || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end

  # sobelow_skip ["XSS.SendResp"]
  defp ping(%{request_path: "/ping"} = conn, _opts) do
    version = Application.get_env(:elixir_practice, :version)
    response = Jason.encode!(%{status: "ok", version: version})

    conn
    |> Conn.put_resp_header("content-type", "application/json")
    |> Conn.send_resp(200, response)
    |> Conn.halt()
  end

  defp ping(conn, _opts), do: conn

  defp canonical_host(%{request_path: "/health"} = conn, _opts), do: conn

  defp canonical_host(conn, _opts) do
    opts = PlugCanonicalHost.init(canonical_host: Application.get_env(:elixir_practice, :canonical_host))

    PlugCanonicalHost.call(conn, opts)
  end

  defp force_ssl(%{request_path: "/health"} = conn, _opts), do: conn

  defp force_ssl(conn, _opts) do
    if Application.get_env(:elixir_practice, :force_ssl) do
      Plug.SSL.call(conn, @plug_ssl)
    else
      conn
    end
  end

  defp cors(conn, _opts) do
    opts = Corsica.init(Application.get_env(:elixir_practice, Corsica))

    Corsica.call(conn, opts)
  end

  defp basic_auth(conn, _opts) do
    basic_auth_config = Application.get_env(:elixir_practice, :basic_auth)

    if basic_auth_config[:username] do
      Plug.BasicAuth.basic_auth(conn, basic_auth_config)
    else
      conn
    end
  end

  # Splitting routers in separate modules has a negative side effect:
  # Phoenix.Router does not check the Plug.Conn state and tries to match the
  # route even if it was already handled/sent by another router.
  defp halt_if_sent(%{state: :sent, halted: false} = conn, _opts), do: halt(conn)
  defp halt_if_sent(conn, _opts), do: conn
end

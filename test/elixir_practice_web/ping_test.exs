defmodule ElixirPracticeWeb.PingTest do
  use ElixirPracticeWeb.ConnCase

  test "GET /ping", %{conn: conn} do
    conn = get(conn, "/ping")

    assert response(conn, 200)
  end
end

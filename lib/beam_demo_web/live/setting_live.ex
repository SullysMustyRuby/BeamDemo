defmodule BeamDemoWeb.SettingsLive do
  use Phoenix.LiveView, layout: {BeamDemoWeb.LayoutView, "live.html"}

  alias BeamDemo.Utils

  def mount(_params, session, socket) do
    settings = Utils.all_settings()
    {:ok, assign(socket, settings: settings, session_id: session["live_socket_id"])}
  end

  def render(assigns) do
    ~H"""
    <table class="table is-striped is-fullwidth is-hoverable">
      <thead>
        <th>Name</th>
        <th>Value</th>
      </thead>
      <tbody>
        <%= for setting <- @settings do %>
          <tr>
            <td><%= setting.name %></td>
            <td><%= setting.value %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    """
  end
end

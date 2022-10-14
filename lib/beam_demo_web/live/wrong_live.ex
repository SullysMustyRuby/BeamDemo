defmodule BeamDemoWeb.WrongLive do
  use Phoenix.LiveView, layout: {BeamDemoWeb.LayoutView, "live.html"}

  def mount(_params, session, socket) do
    {:ok,
     assign(socket,
       score: 0,
       message: "Make a guess:",
       time: time(),
       number: "#{Enum.random(1..10)}",
       played: 0,
       session_id: session["live_socket_id"]
     )}
  end

  def handle_event("guess", %{"number" => guess}, socket) do
    new_socket =
      socket.assigns.number
      |> handle_guess(guess, socket)
      |> assign(time: time())

    {:noreply, new_socket}
  end

  def render(assigns) do
    ~H"""
      <h1>Your score: <%= @score %></h1>
      <h2>
        <%= @message %>
      </h2>
      <h2>
        <%= for n <- 1..10 do %>
          <a href="#" phx-click="guess" phx-value-number= {n} ><%= n %></a>
        <% end %>
    </h2>
    <h3>It's <%= @time %></h3>
    <h3>Games played: <%= @played %></h3>
    <pre>
      <%= @current_user.email %>
      <%= @session_id %>
    </pre>
    """
  end

  def handle_guess(number, number, socket) do
    assign(
      socket,
      message: "Correct!!",
      number: "#{Enum.random(1..10)}",
      score: socket.assigns.score + 1,
      played: socket.assigns.played + 1
    )
  end

  def handle_guess(_number, guess, socket) do
    assign(
      socket,
      message: "Your guess: #{guess}. Wrong. Guess again. ",
      score: socket.assigns.score - 1,
      played: socket.assigns.played + 1
    )
  end

  def time() do
    DateTime.utc_now() |> to_string
  end
end

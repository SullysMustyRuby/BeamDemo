# BeamDemo

A demo application of [ActiveMemory](https://hex.pm/packages/active_memory) hex package

## Demo setup
1. Run `mix deps.get` on this app
2. (Optional) if you want to run multiple copies of this app in a cluster. Copy this app into a new directory and modify the endpoint port (ex: 4001)
2. Download the [MnesiaManager](https://github.com/SullysMustyRuby/ActiveMemoryManager) app and run `mix deps.get`

## Demo Instructions
1. Start the MnesiaManager:
```bash
iex --sname mnesia_manager@localhost -S mix
```
2. If your booting all these apps for the first time setup the schema. From the ActiveMemory Manager iex terminal run:
```elixir
iex> MnesiaManager.create_schema()
```
3. In a second terminal start this app:
```bash
iex --sname demo1@localhost -S mix phx.server
```
4. (optional)  In third terminal start the second version of this app:
```bash
iex --sname demo2@localhost -S mix phx.server
````
5. Go to your browser and view each app based on your ports/etc. 
Generally the demo1 is: http://localhost:4000 
and demo2 is: http://localhost:4001

## Demo Play
- Start with all tables as :ets 
- Adjust table types: ram_copies, disc_copies, etc.
- Experiment with Store initial_state, seeding, and before init options
- Start more copies of this app for a larger cluster

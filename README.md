# BeamDemo

A demo application of [ActiveMemory](https://hex.pm/packages/active_memory) hex package
Initially this uses the [MnesiaManager](https://github.com/SullysMustyRuby/ActiveMemoryManager) application for running Mnesia. 
However you can configure the application to boot alone without the MnesiaManager.

## Demo setup
1. Run `mix deps.get` on this app

2. (Optional) if you want to run multiple copies of this app in a cluster. Copy this app into a new directory and modify the endpoint port (ex: 4001)

3. Download the [MnesiaManager](https://github.com/SullysMustyRuby/ActiveMemoryManager) app and run `mix deps.get`

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

6. Login as any one of the users in the `/priv/user_seeds.exs` file.

## Demo Play
- Change to all tables to :ets 
- Adjust table types: ram_copies, disc_copies, etc.
- Experiment with Store initial_state, seeding, and before init options
- Start more copies of this app for a larger cluster
- Create a new module using a `Table` and `Store`
- Create more complex queries using the ActiveMemory Key Value syntax
- Create more complex queries using the ActiveMemory [match](https://hexdocs.pm/active_memory/ActiveMemory.Query.html#module-the-match-query-syntax) syntax
- Change the `hero_css` setting from: `green-phx-hero` to: `purple-phx-hero` as a simple example of updating an application setting while the application is running. 
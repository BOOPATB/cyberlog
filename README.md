## Logs with Classes and Lists

- A `Log` class was created with three properties: `action`, `timestamp`, and `status`. This class also has a `formatted()` method that returns a readable string combining these fields.
- In the UI, a `List<Log>` is used to hold multiple log entries (for example, "App started", "User logged in", etc.).
- The list is iterated using `logs.map((log) => Text(log.formatted()))`, which converts each `Log` object into a `Text` widget. This shows how classes structure the data, while list iteration (a loop) efficiently renders multiple widgets on the screen.

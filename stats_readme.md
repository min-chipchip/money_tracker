# Statistics Page Documentation (`stats.dart`)

This file is responsible for displaying the history of transactions. It retrieves data from the SQLite database and presents it in a scrollable list.

---

## 1. The Structure
The page is a `StatefulWidget` because it needs to interact with the database asynchronously.

- **`DatabaseHelper dbHelper`**: An instance of your database manager. It is used to call `getTransactions()`.
- **`backgroundColor: Colors.transparent`**: This allows the background colors or gradients defined in `main.dart` to show through this page.

---

## 2. The FutureBuilder (The Engine)
Because reading from a database takes time, we use a `FutureBuilder`. It acts as a "listener" that waits for the data to arrive.

- **`future: dbHelper.getTransactions()`**: Tells the builder to start fetching the data.
- **`snapshot`**: An object containing the current state of the data.

### Logic States:
1. **Waiting**: While the database is busy, it returns a `CircularProgressIndicator` (loading spinner).
2. **Error**: If something goes wrong, it displays the error text.
3. **Empty**: If the database is connected but contains no rows, it calls the `_buildEmptyState()` helper.

---

## 3. The ListView.builder
Once the data is ready (`snapshot.data`), it is displayed using a `ListView.builder`.

- **Efficiency**: Unlike a standard Column, `ListView.builder` only renders the items currently visible on the screen. This makes the app stay fast even if you have 1,000 transactions.
- **`itemCount`**: Set to the length of the list retrieved from the database.
- **`itemBuilder`**: A loop that creates a `Card` for every transaction in the list.

---

## 4. UI Components

### The Card
Each transaction is wrapped in a `Card` with an `elevation: 5`, giving it a shadow and making it look "raised" off the screen.

### The ListTile
Inside the card, we use a standard Flutter `ListTile`:
- **Leading**: Shows a blue money icon.
- **Title**: Shows the Category and the Amount (formatted with a `$` sign).
- **Subtitle**: Shows the Date and the Account (e.g., Cash or Bank).
- **Trailing (The Star)**:
    - Uses a **Conditional Operator** (`? :`).
    - If `item.isHighlighted == 1`, it shows a filled yellow star.
    - Otherwise, it shows a grey star border.

---

## 5. Empty State Helper (`_buildEmptyState`)
This is a private helper function. When there are no transactions to show:
- It displays a large `pie_chart_rounded` icon.
- It shows a friendly message prompting the user to add entries.
- This keeps the user experience clean instead of just showing a blank white screen.

---

## 6. Connection to main.dart
This file is integrated into `main.dart` via the `BottomNavigationBar`. When the "Stats" tab is clicked, the `_pages` list in `main.dart` points to `MyStatsPage()`, triggering the `FutureBuilder` to refresh the data.
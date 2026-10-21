A Flutter assessment project that implements an **Order Listing UI** backed by a mock orders API. Built with GetX for state management, routing, and dependency injection.

---

## Features

- **Order listing** with paginated infinite scroll (20 orders per page, 237 total)
- **Real-time search** by customer name, city, or order ID (debounced 400 ms)
- **Status filter chips** — All, Pending, Confirmed, Shipped, Delivered, Cancelled, Refunded
- **Sort** by Date, Amount, or Customer Name (asc/desc) via a bottom sheet
- **Pull-to-refresh** to reload the list from the top
- **Loading, error, and empty states** with retry and clear-filters actions
- Order cards showing ID, customer, city, amount, item count, date, and a colour-coded status badge
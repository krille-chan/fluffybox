## 0.6.1
- fix: Return type for getAllValues

## 0.6.0
- Switch back to sqflite for native

## 0.1.7
- fix: Do use sqflite batches instead of transactions

## 0.1.6
- feat: Create indexes if not exists

## 0.1.5
- refactor: Move pragmas outside of creation

## 0.1.4
- fix: Dont set pragmas in transactions

## 0.1.3
- feat: Speed up sqflite by setting Pragmas:
```sql
PRAGMA page_size = 8192
PRAGMA cache_size = 16384
PRAGMA temp_store = MEMORY
PRAGMA journal_mode = WAL
```

## 0.1.2
- feat: Use batches to speed up transactions in sqflite

## 0.1.1
- fix: Lower Dart dependency to 2.12

## 0.1.0

- Initial version.

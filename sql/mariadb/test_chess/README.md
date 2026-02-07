# Chess Schema

<div align="left">

![Author](https://img.shields.io/badge/Author-Szymon%20Derleta-white?style=for-the-badge)

![Release](https://img.shields.io/badge/Release-Public%20Release-green?style=for-the-badge)  
![Version](https://img.shields.io/badge/Version-2.0.0-green?style=for-the-badge)

</div>

## Repository structure

This repository contains the chess schema and related materials.
Structure
```filetree
tables/ – Contains individual SQL files generated for each database table.
test_data/ – Stores sql files with insert queries used in test_nebula database.

views/ – Contains individual SQL files generated for views.
routines/ - Contains routines (stored procedures, functions, triggers) used in the database.
events/ - Contains event definitions used in the database.
model/ – Includes the latest full database schema exported from DataGrip. A preview of the current model is shown below.
```

## Database configuration:

1. Scheduling a task in MariaDB (using the Event Scheduler)

```sql
SET GLOBAL event_scheduler = ON;
```

## Preview

Current Model Preview

![chess-2025-11-26.png](model/chess-2025-11-26.png)

Chess Schema - 2025-11-26

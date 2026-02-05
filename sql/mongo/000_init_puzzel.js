// Switch to the 'puzzle' database (it will be created on first write)
db = db.getSiblingDB('test_puzzel');

// Create a dedicated user for the puzzle database
db.createUser({
    user: "puzzel",
    pwd: "puzzel-secret-password", // You should replace this with a placeholder or variable
    roles: [
        {
            role: "readWrite",
            db: "test_puzzel"
        }
    ]
});

// Create an initial collection to ensure the database is actually created
// MongoDB doesn't "persist" a DB until it has at least one document or collection
db.createCollection('metadata');

// Optional: Insert a dummy document to confirm initialization
db.metadata.insert({
    version: "0.1.0",
    description: "Initial setup for test_puzzel database",
    created_at: new Date()
});

console.log("Database 'test_puzzel' and user 'test_puzzel' initialized successfully.");
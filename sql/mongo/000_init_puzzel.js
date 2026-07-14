// Bootstrap the test_puzzel database and its dedicated user.
//
// This file is committed to a public repository — it must never contain a literal
// password. The value is read from PUZZEL_PASSWORD, which mongo.env passes into the
// container; mongosh exposes the container environment as process.env.
//
// Init scripts in /docker-entrypoint-initdb.d run ONLY when the data directory is
// empty. The volume already holds data, so editing this file changes nothing for the
// existing deployment — rotate the live password with db.changeUserPassword() instead
// (see the secrets master file). This script matters for a rebuild from scratch.

const puzzelPassword = process.env.PUZZEL_PASSWORD;

if (!puzzelPassword) {
    throw new Error(
        "PUZZEL_PASSWORD is not set. Add it to env/db/mongo.env " +
        "(see env/db/mongo.env.example) before initialising an empty MongoDB volume."
    );
}

db = db.getSiblingDB('test_puzzel');

db.createUser({
    user: "puzzel",
    pwd: puzzelPassword,
    roles: [
        {
            role: "readWrite",
            db: "test_puzzel"
        }
    ]
});

// MongoDB does not persist a database until it holds a collection.
db.createCollection('metadata');

db.metadata.insertOne({
    version: "0.1.0",
    description: "Initial setup for test_puzzel database",
    created_at: new Date()
});

console.log("Database 'test_puzzel' and user 'puzzel' initialized successfully.");

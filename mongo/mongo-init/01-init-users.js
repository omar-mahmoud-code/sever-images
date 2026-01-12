// MongoDB Initialization Script - Create application users
// This runs once when MongoDB is first initialized

// Switch to admin database
db = db.getSiblingDB('admin');

// Create backup user with read-only access to all databases
db.createUser({
  user: 'backup_user',
  pwd: 'CHANGE_THIS_BACKUP_PASSWORD',
  roles: [
    { role: 'backup', db: 'admin' },
    { role: 'restore', db: 'admin' }
  ]
});

// Create monitoring user
db.createUser({
  user: 'monitoring_user',
  pwd: 'CHANGE_THIS_MONITORING_PASSWORD',
  roles: [
    { role: 'clusterMonitor', db: 'admin' },
    { role: 'read', db: 'local' }
  ]
});

// Create application database and user
db = db.getSiblingDB('orcatrack');

db.createUser({
  user: 'orcatrack_app',
  pwd: 'CHANGE_THIS_APP_PASSWORD',
  roles: [
    { role: 'readWrite', db: 'orcatrack' },
    { role: 'dbAdmin', db: 'orcatrack' }
  ]
});

// Create initial collections with validation
db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: 'object',
      required: ['email', 'createdAt'],
      properties: {
        email: {
          bsonType: 'string',
          description: 'must be a string and is required'
        },
        createdAt: {
          bsonType: 'date',
          description: 'must be a date and is required'
        }
      }
    }
  }
});

// Create indexes
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ createdAt: -1 });

print('MongoDB initialization completed successfully!');

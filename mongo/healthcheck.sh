#!/bin/bash
# MongoDB Health Check Script
# Usage: ./healthcheck.sh

set -e

MONGO_HOST="${MONGO_HOST:-localhost}"
MONGO_PORT="${MONGO_PORT:-27017}"
MONGO_USER="${MONGO_ROOT_USERNAME:-root}"
MONGO_PASSWORD="${MONGO_ROOT_PASSWORD:-Admin@2014}"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== MongoDB Health Check ==="
echo "Host: $MONGO_HOST:$MONGO_PORT"
echo ""

# Check if MongoDB is running
if ! docker ps | grep -q mongodb; then
    echo -e "${RED}✗ MongoDB container is not running${NC}"
    exit 1
fi

echo -e "${GREEN}✓ MongoDB container is running${NC}"

# Check MongoDB connectivity
if docker exec mongodb mongosh --quiet --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ MongoDB is responding to connections${NC}"
else
    echo -e "${RED}✗ MongoDB is not responding${NC}"
    exit 1
fi

# Check authentication
if docker exec mongodb mongosh --quiet -u "$MONGO_USER" -p "$MONGO_PASSWORD" --authenticationDatabase admin --eval "db.adminCommand('ping')" > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Authentication is working${NC}"
else
    echo -e "${RED}✗ Authentication failed${NC}"
    exit 1
fi

# Get server status
echo ""
echo "=== Server Status ==="
docker exec mongodb mongosh --quiet -u "$MONGO_USER" -p "$MONGO_PASSWORD" --authenticationDatabase admin --eval "
    var status = db.serverStatus();
    print('Version: ' + status.version);
    print('Uptime: ' + Math.floor(status.uptimeMillis / 1000 / 60) + ' minutes');
    print('Current Connections: ' + status.connections.current);
    print('Available Connections: ' + status.connections.available);
    print('Total Requests: ' + status.opcounters.command);
"

# Check disk usage
echo ""
echo "=== Disk Usage ==="
docker exec mongodb df -h /data/db | tail -n 1

# Check databases
echo ""
echo "=== Databases ==="
docker exec mongodb mongosh --quiet -u "$MONGO_USER" -p "$MONGO_PASSWORD" --authenticationDatabase admin --eval "
    db.adminCommand('listDatabases').databases.forEach(function(db) {
        print(db.name + ': ' + (db.sizeOnDisk / 1024 / 1024).toFixed(2) + ' MB');
    });
"

# Check replication status (if applicable)
echo ""
echo "=== Replication Status ==="
REPL_STATUS=$(docker exec mongodb mongosh --quiet -u "$MONGO_USER" -p "$MONGO_PASSWORD" --authenticationDatabase admin --eval "rs.status()" 2>&1)
if echo "$REPL_STATUS" | grep -q "no replset config"; then
    echo -e "${YELLOW}⚠ Not configured as replica set${NC}"
else
    echo "$REPL_STATUS"
fi

# Check slow queries
echo ""
echo "=== Recent Slow Queries (>100ms) ==="
docker exec mongodb mongosh --quiet -u "$MONGO_USER" -p "$MONGO_PASSWORD" --authenticationDatabase admin --eval "
    db.getSiblingDB('admin').system.profile.find().limit(5).forEach(function(query) {
        if (query.millis) {
            print('Duration: ' + query.millis + 'ms | ' + query.op + ' on ' + query.ns);
        }
    });
" 2>/dev/null || echo "No slow queries found"

echo ""
echo -e "${GREEN}=== Health Check Complete ===${NC}"

exit 0

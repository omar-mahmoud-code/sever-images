#!/bin/bash
# MongoDB Docker Compose Management Script
# Quick commands for common operations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}MongoDB Docker Management Commands${NC}"
    echo ""
    echo "Usage: ./manage.sh [command]"
    echo ""
    echo "Commands:"
    echo "  start          - Start MongoDB container"
    echo "  start-admin    - Start MongoDB + Mongo Express (admin UI)"
    echo "  stop           - Stop all containers"
    echo "  restart        - Restart MongoDB"
    echo "  logs           - Show MongoDB logs (follow)"
    echo "  status         - Show container status"
    echo "  health         - Run health check"
    echo "  shell          - Open MongoDB shell"
    echo "  backup [db]    - Backup database (optional: specific database)"
    echo "  restore <file> - Restore from backup file"
    echo "  reset          - ⚠️  Reset everything (delete all data)"
    echo "  update         - Pull latest image and restart"
    echo ""
    echo "Examples:"
    echo "  ./manage.sh start"
    echo "  ./manage.sh backup orcatrack"
    echo "  ./manage.sh restore /backups/mongodb/backup.tar.gz"
}

case "${1:-}" in
    start)
        echo -e "${GREEN}Starting MongoDB...${NC}"
        docker network create central-net 2>/dev/null || true
        docker-compose up -d mongodb
        echo -e "${GREEN}✓ MongoDB started${NC}"
        echo "Run './manage.sh health' to check status"
        ;;
    
    start-admin)
        echo -e "${GREEN}Starting MongoDB + Mongo Express...${NC}"
        docker network create central-net 2>/dev/null || true
        docker-compose --profile admin up -d
        echo -e "${GREEN}✓ Services started${NC}"
        echo "MongoDB: mongodb://localhost:27017"
        echo "Mongo Express: http://localhost:8081"
        ;;
    
    stop)
        echo -e "${YELLOW}Stopping containers...${NC}"
        docker-compose down
        echo -e "${GREEN}✓ Stopped${NC}"
        ;;
    
    restart)
        echo -e "${YELLOW}Restarting MongoDB...${NC}"
        docker-compose restart mongodb
        echo -e "${GREEN}✓ Restarted${NC}"
        ;;
    
    logs)
        echo -e "${BLUE}MongoDB logs (Ctrl+C to exit):${NC}"
        docker-compose logs -f mongodb
        ;;
    
    status)
        echo -e "${BLUE}Container Status:${NC}"
        docker-compose ps
        echo ""
        echo -e "${BLUE}Resource Usage:${NC}"
        docker stats mongodb --no-stream 2>/dev/null || echo "Container not running"
        ;;
    
    health)
        ./healthcheck.sh
        ;;
    
    shell)
        echo -e "${BLUE}Opening MongoDB shell...${NC}"
        docker exec -it mongodb mongosh -u root -p Admin@2014 --authenticationDatabase admin
        ;;
    
    backup)
        ./backup.sh "$2"
        ;;
    
    restore)
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Backup file required${NC}"
            echo "Usage: ./manage.sh restore <backup_file.tar.gz>"
            exit 1
        fi
        ./restore.sh "$2" "$3"
        ;;
    
    reset)
        echo -e "${RED}⚠️  WARNING: This will DELETE ALL DATA!${NC}"
        read -p "Are you sure? Type 'yes' to confirm: " confirm
        if [ "$confirm" = "yes" ]; then
            echo -e "${YELLOW}Resetting everything...${NC}"
            docker-compose down -v
            echo -e "${GREEN}✓ Reset complete${NC}"
            echo "Run './manage.sh start' to start fresh"
        else
            echo "Cancelled"
        fi
        ;;
    
    update)
        echo -e "${YELLOW}Updating MongoDB image...${NC}"
        docker-compose pull mongodb
        docker-compose up -d mongodb
        echo -e "${GREEN}✓ Updated${NC}"
        ;;
    
    *)
        show_help
        exit 0
        ;;
esac

exit 0

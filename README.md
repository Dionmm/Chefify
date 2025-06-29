# Chefify

A modern recipe app with integrated shopping list functionality.

## Overview

Chefify is a comprehensive recipe management application that combines recipe organization with smart shopping list generation, making meal planning and grocery shopping seamless and efficient.

## Features

- Recipe management and organization
- Integrated shopping list generation
- Meal planning capabilities
- Cross-platform support

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Git

### Local Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/Dionmm/Chefify.git
   cd Chefify
   ```

2. Copy the environment variables template:
   ```bash
   cp .env.example .env
   ```

3. Update the `.env` file with your specific configuration values (especially OIDC settings).

4. Start the development environment:
   ```bash
   docker-compose up --build
   ```

5. The application will be available at:
   - Frontend: http://localhost:3000
   - API: http://localhost:5000
   - Database: localhost:5432

### Development Services

- **PostgreSQL 15**: Database with recipe schema pre-loaded
- **.NET 8 API**: Backend API with hot reload support
- **React Frontend**: Frontend application with hot reload support

### Hot Reload

The development setup includes hot reload for both backend and frontend:
- Backend: Uses `dotnet watch` for automatic rebuilds
- Frontend: Uses React development server with file watching

### Database

The PostgreSQL database is initialized with:
- Chefify-specific schema from `recipes.sql`
- Basic extensions and configuration from `database/init.sql`
- Persistent data storage via Docker volumes

## Technologies

- **Backend**: .NET 8 with Clean Architecture
- **Frontend**: React 18
- **Database**: PostgreSQL 15
- **Development**: Docker Compose for local development
- **Authentication**: OIDC integration ready

## Contributing

*Guidelines coming soon...*

## License

*To be determined*
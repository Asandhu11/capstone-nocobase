# NocoBase Setup Guide

This project provides a ready-to-run [Docker Compose](https://docker.com) setup for deploying [NocoBase](https://www.nocobase.com/), an open-source, private, no-code/low-code platform.

## Prerequisites

Before running the application, make sure you have the following installed on your machine:
* [Docker Desktop](https://docker.com) (Windows / macOS) or Docker Engine (Linux)
* Docker Compose v2 (included with Docker Desktop)

## Getting Started

Follow these steps to launch the NocoBase environment:

### 1. Project Directory Configuration
Ensure both `compose.yml` and `README.md` are saved in the same root folder.

### 2. Launch the Stack
Open your terminal or command prompt inside your project directory and execute the following command:

```bash
docker compose up -d
```

*The `-d` flag runs the containers in detached mode (in the background).*

### 3. Monitor Initial Setup
NocoBase performs database migrations and configures itself on the first boot. You can track its progress by monitoring the logs:

```bash
docker compose logs -f nocobase-app
```
Look for lines indicating that the server has started successfully.

## Accessing NocoBase

Once the containers are successfully running, open your web browser and navigate to:

--> **[http://localhost:13000](http://localhost:13000)**

### Default Login Credentials

Use the official default administrative credentials below to access your local dashboard:

* **Email/Username:** `admin@nocobase.com`
* **Password:** `admin123`

> **Security Warning:** Change this password immediately inside the user profile management view upon logging in for the first time.

## Useful Management Commands

* **Stop the server:** Keep data intact but shut down services.
  ```bash
  docker compose down
  ```
* **View Container Status:** Check if services are healthy and running.
  ```bash
  docker compose ps
  ```
* **Wipe Data / Hard Reset:** To completely reset your NocoBase installation back to default, remove the persistent volumes:
  ```bash
  docker compose down -v
  ```

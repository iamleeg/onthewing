# On The Wing

On The Wing is your digital nature journal, built on GNUstep WebObjects and libgdl2 (Enterprise Objects Framework). It integrates Firebase Authentication with a PostgreSQL database to manage users, captures, and nature observations.

---

## Local Development Guide

This guide explains how to set up the development environment, configure the local database, and run/test the application locally using **Skaffold** and **Kubernetes** (e.g., Minikube).

### Prerequisites

Ensure you have the following installed on your development machine:
1. **Kubernetes Cluster**: [Minikube](https://minikube.sigs.k8s.io/docs/start/) (recommended) or a similar local Kubernetes provider.
2. **Skaffold**: [Skaffold CLI](https://skaffold.dev/docs/install/) for continuous local development.
3. **PostgreSQL 18**: Local database server.
4. **Node.js & npm**: For running frontend tests and asset management.
5. **GNUstep / WebObjects / GDL2**: The core frameworks.

---

### Step 1: Start the Local PostgreSQL Server

Start the PostgreSQL 18 database server on your host machine. For macOS Homebrew installations:

```bash
LC_ALL="en_US.UTF-8" /opt/homebrew/opt/postgresql@18/bin/postgres -D /opt/homebrew/var/postgresql@18
```

*Note: If you are developing on a different system (e.g. Linux or Intel Mac), start the PostgreSQL service using your system's package manager/service runner.*

---

### Step 2: Create the Development Database

Create the database named `onthewing-eedce-database` on your local PostgreSQL instance:

```bash
createdb onthewing-eedce-database
```

*(You don't need to import any schemas or create tables manually; the application dynamically checks for the presence of the `users` table and creates it on startup).*

---

### Step 3: Run the Application with Skaffold

Skaffold automates the build, deployment, and port-forwarding of the application inside Kubernetes. Run the following command in the root folder of the project:

```bash
skaffold dev
```

Skaffold will:
1. Build the app container image.
2. Deploy the manifests using the configurations under [local-dev/kustomization.yaml](file:///Users/leeg/src/onthewing/local-dev/kustomization.yaml).
3. Port-forward the container's port to your local machine at `http://localhost:8080/`.

You can now open your browser and navigate to:
**[http://localhost:8080/](http://localhost:8080/)**

---

### How Database Connectivity Works in Local Dev

The app runs containerized inside Minikube but connects to the host machine's PostgreSQL instance. This connection is configured in [local-dev/kustomization.yaml](file:///Users/leeg/src/onthewing/local-dev/kustomization.yaml) using the special hostname:
* **`host.minikube.internal`**

If your host PostgreSQL configuration requires a specific user, password, or port, you can update the values in the `env` patch section of [local-dev/kustomization.yaml](file:///Users/leeg/src/onthewing/local-dev/kustomization.yaml).

---

## Running Quality Gates & Tests

To run the full suite of Objective-C unit tests (via XCTest) and JavaScript tests (via Jest):

```bash
make check
```

For manual docker/container builds verification:
```bash
make podman-check
```

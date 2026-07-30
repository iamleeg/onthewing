# On The Wing

On The Wing is your digital nature journal, built on GNUstep WebObjects and libgdl2 (Enterprise Objects Framework). It integrates Firebase Authentication with a PostgreSQL database to manage users, captures, and nature observations.

## Running Quality Gates & Tests

To run the full suite of Objective-C unit tests (via XCTest) and JavaScript tests (via Jest):

```bash
make check
```

For manual docker/container builds verification:
```bash
make podman-check
```

### End-to-End (E2E) Tests

To run the End-to-End tests headlessly inside the local development cluster (Minikube):
```bash
make test-e2e-cluster
```

To run e2e tests using a local browser, with the app in minikube:

```bash
make test-e2e
```

To add new E2E tests:
1. Create a new `.feature` file in `test/e2e/features/` using Cucumber (Gherkin) syntax.
2. Implement any missing step definitions in `test/e2e/steps/`.
3. The browser and test lifecycle is managed automatically in `test/e2e/support/`.

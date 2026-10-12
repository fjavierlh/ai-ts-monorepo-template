export default {
  options: {
    doNotFollow: {
      path: "node_modules",
      dependencyTypes: [
        "npm",
        "npm-dev",
        "npm-optional",
        "npm-peer",
        "npm-bundled",
        "npm-no-pkg",
      ],
    },
  },
  forbidden: [
    {
      name: "no-circular",
      severity: "error",
      from: {},
      to: { circular: true },
    },
    {
      name: "commons-no-app",
      severity: "error",
      from: { path: "^packages/commons/" },
      to: { path: "^apps/" },
    },
    {
      name: "backend-no-frontend",
      severity: "error",
      from: { path: "^apps/backend/" },
      to: { path: "^apps/frontend/" },
    },
    {
      name: "frontend-no-backend",
      severity: "error",
      from: { path: "^apps/frontend/" },
      to: { path: "^apps/backend/" },
    },
    {
      name: "not-to-unresolvable",
      severity: "error",
      from: {},
      to: { couldNotResolve: true },
    },
  ],
};

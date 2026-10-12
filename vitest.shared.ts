import type { UserConfig } from "vitest/config";

export const sharedTestConfig: UserConfig["test"] = {
  passWithNoTests: true,
};

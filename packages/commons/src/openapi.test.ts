import { expectTypeOf, it } from "vitest";
import type { paths } from "./generated/openapi.js";

it("keeps the health response status as the literal ok", () => {
  expectTypeOf<
    paths["/health"]["get"]["responses"][200]["content"]["application/json"]["status"]
  >().toEqualTypeOf<"ok">();
});


import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const wallet1 = accounts.get("wallet_1")!;

describe("oracle contract", () => {
  it("allows owner to update stablecoin price after delay", () => {
    simnet.mineEmptyBlocks(101);

    let result = simnet.callPublicFn(
      "oracle",
      "set-stablecoin-price",
      [Cl.uint(101_000_000)],
      deployer,
    );
    expect(result.result).toBeOk(Cl.bool(true));

    result = simnet.callReadOnlyFn("oracle", "get-stablecoin-price", [], deployer);
    expect(result.result).toBeOk(Cl.uint(101_000_000));
  });

  it("rejects non-owner updates", () => {
    simnet.mineEmptyBlocks(101);

    const result = simnet.callPublicFn(
      "oracle",
      "set-stablecoin-price",
      [Cl.uint(102_000_000)],
      wallet1,
    );
    expect(result.result).toBeErr(Cl.uint(100));
  });

  it("supports emergency price updates", () => {
    const result = simnet.callPublicFn(
      "oracle",
      "emergency-set-price",
      [Cl.uint(0), Cl.uint(95_000_000)],
      deployer,
    );
    expect(result.result).toBeOk(Cl.bool(true));
  });
});

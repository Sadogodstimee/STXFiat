
import { describe, expect, it } from "vitest";
import { Cl } from "@stacks/transactions";

const accounts = simnet.getAccounts();
const deployer = accounts.get("deployer")!;
const wallet1 = accounts.get("wallet_1")!;
const wallet2 = accounts.get("wallet_2")!;
const oraclePrincipal = Cl.contractPrincipal(deployer, "oracle");

const setupStxFiat = () => {
  let result = simnet.callPublicFn("STXFiat", "initialize", [], deployer);
  expect(result.result).toBeOk(Cl.bool(true));

  result = simnet.callPublicFn("STXFiat", "set-price-oracle", [oraclePrincipal], deployer);
  expect(result.result).toBeOk(Cl.bool(true));

  result = simnet.callPublicFn(
    "STXFiat",
    "add-collateral-type",
    [
      oraclePrincipal,
      oraclePrincipal,
      Cl.uint(150),
      Cl.uint(130),
      Cl.uint(5),
      Cl.uint(1_000_000),
    ],
    deployer,
  );
  expect(result.result).toBeOk(Cl.bool(true));
};

describe("STXFiat core flows", () => {
  it("initializes and wires the oracle", () => {
    setupStxFiat();
  });

  it("mints and repays stablecoin", () => {
    setupStxFiat();

    let result = simnet.callPublicFn(
      "STXFiat",
      "deposit-collateral-and-mint",
      [oraclePrincipal, Cl.uint(100), Cl.uint(1000)],
      wallet1,
    );
    expect(result.result).toBeOk(Cl.bool(true));

    result = simnet.callReadOnlyFn("STXFiat", "balance-of", [Cl.principal(wallet1)], wallet1);
    expect(result.result).toBeOk(Cl.uint(1000));

    result = simnet.callReadOnlyFn("STXFiat", "get-total-supply", [], wallet1);
    expect(result.result).toBeOk(Cl.uint(1000));

    result = simnet.callPublicFn(
      "STXFiat",
      "repay-debt-and-withdraw",
      [oraclePrincipal, Cl.uint(400), Cl.uint(10)],
      wallet1,
    );
    expect(result.result).toBeOk(Cl.bool(true));

    result = simnet.callReadOnlyFn("STXFiat", "balance-of", [Cl.principal(wallet1)], wallet1);
    expect(result.result).toBeOk(Cl.uint(600));

    result = simnet.callReadOnlyFn("STXFiat", "get-total-supply", [], wallet1);
    expect(result.result).toBeOk(Cl.uint(600));
  });

  it("liquidates an unsafe position", () => {
    setupStxFiat();

    let result = simnet.callPublicFn(
      "STXFiat",
      "deposit-collateral-and-mint",
      [oraclePrincipal, Cl.uint(100), Cl.uint(1000)],
      wallet1,
    );
    expect(result.result).toBeOk(Cl.bool(true));

    result = simnet.callPublicFn(
      "oracle",
      "emergency-set-price",
      [Cl.uint(0), Cl.uint(1)],
      deployer,
    );
    expect(result.result).toBeOk(Cl.bool(true));

    result = simnet.callPublicFn(
      "STXFiat",
      "liquidate-position",
      [Cl.principal(wallet1), oraclePrincipal],
      wallet2,
    );
    expect(result.result).toBeOk(Cl.bool(true));

    result = simnet.callReadOnlyFn(
      "STXFiat",
      "get-user-position",
      [Cl.principal(wallet1), oraclePrincipal],
      wallet2,
    );
    expect(result.result).toBeOk(Cl.none());
  });
});

import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test loan request creation",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const block = chain.mineBlock([
      Tx.contractCall('stackfin', 'request-loan', 
        [types.uint(1000000), types.uint(1200000), types.uint(30)], 
        wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectUint(1);
    const loan = chain.callReadOnlyFn('stackfin', 'get-loan-data', [types.uint(1)], wallet1.address);
    loan.result.expectOk().expectTuple();
  }
});

Clarinet.test({
  name: "Test loan funding",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('stackfin', 'request-loan',
        [types.uint(1000000), types.uint(1200000), types.uint(30)],
        wallet1.address)
    ]);
    
    block = chain.mineBlock([
      Tx.contractCall('stackfin', 'fund-loan',
        [types.uint(1)],
        wallet2.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Test loan repayment",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('stackfin', 'request-loan',
        [types.uint(1000000), types.uint(1200000), types.uint(30)],
        wallet1.address),
      Tx.contractCall('stackfin', 'fund-loan',
        [types.uint(1)],
        wallet2.address)
    ]);
    
    block = chain.mineBlock([
      Tx.contractCall('stackfin', 'repay-loan',
        [types.uint(1)],
        wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
  }
});

Clarinet.test({
  name: "Test collateral claim on default",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet1 = accounts.get('wallet_1')!;
    const wallet2 = accounts.get('wallet_2')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('stackfin', 'request-loan',
        [types.uint(1000000), types.uint(1200000), types.uint(30)],
        wallet1.address),
      Tx.contractCall('stackfin', 'fund-loan',
        [types.uint(1)],
        wallet2.address)
    ]);
    
    chain.mineEmptyBlockUntil(35);
    
    block = chain.mineBlock([
      Tx.contractCall('stackfin', 'claim-collateral',
        [types.uint(1)],
        wallet2.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
  }
});

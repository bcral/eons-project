const { expect } = require("chai");

describe("Deployment", function() {

  let usdc = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48';
  let ausdc = '0xbcca60bb61934080951369a648fb03df4f96263c';
  let aaveLP = '0x88757f2f99175387ab4c6a4b3067c77a695b0349';

  beforeEach( async () => {
    [owner, w1, w2, _] = await ethers.getSigners();
    const E = await ethers.getContractFactory("eaEons");
    e = await E.deploy(ausdc, c.address);
    await e.deployed();
  });

  it("Should test deposit functionality", async function() {
    
    expect(await e.getCurrentIndex()).to.equal(1);

    // expect(await greeter.greet()).to.equal("Hola, mundo!");
  });
});

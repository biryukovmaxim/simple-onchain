import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer } from "ethers";

describe("Sender", function () {
  let accounts: Signer[];

  beforeEach(async function () {
    accounts = await ethers.getSigners();
  });

  describe("createTransferPermitted", function () {
    it("should create a permitted transfer", async function () {
      const executor = accounts[0];
      const alice = accounts[1];

      // Deploy the MockToken contract
      const MockToken = await ethers.getContractFactory("MockToken");
      const mockToken = await MockToken.deploy();
      await mockToken.waitForDeployment();

      // Mint some tokens to the first account
      await mockToken.mint(
        await alice.getAddress(),
        ethers.parseUnits("1000", 18)
      );

      // Deploy the Sender contract
      const Sender = await ethers.getContractFactory("Sender");
      const sender = await Sender.deploy(
        mockToken.getAddress(),
        await executor.getAddress()
      );
      await sender.waitForDeployment();

      // Prepare the permit signature
      const nonce = await mockToken.nonces(await alice.getAddress());
      const deadline = Math.floor(Date.now() / 1000) + 60 * 60; // 1 hour from now
      const value = ethers.parseUnits("100", 18);

      // set the domain parameters
      const domain = {
        name: await mockToken.name(),
        version: "1",
        chainId: 31337,
        verifyingContract: await mockToken.getAddress(),
      };

      // set the Permit type parameters
      const types = {
        Permit: [
          {
            name: "owner",
            type: "address",
          },
          {
            name: "spender",
            type: "address",
          },
          {
            name: "value",
            type: "uint256",
          },
          {
            name: "nonce",
            type: "uint256",
          },
          {
            name: "deadline",
            type: "uint256",
          },
        ],
      };

      // set the Permit type values
      const values = {
        owner: await alice.getAddress(),
        spender: await sender.getAddress(),
        value: value,
        nonce: nonce,
        deadline: deadline,
      };

      // sign the Permit type data with the deployer's private key
      const signature = await alice.signTypedData(domain, types, values);
      const sig = ethers.Signature.from(signature);
      const extId = ethers.randomBytes(16);
      const encodedDst = ethers.randomBytes(31);
      const encodedMsg = ethers.randomBytes(33);
      // Call createTransferPermitted
      const tx = await sender
        .connect(alice)
        .createTransferPermitted(
          value,
          extId,
          encodedDst,
          encodedMsg,
          deadline,
          sig.v,
          sig.r,
          sig.s
        );

      expect(await mockToken.balanceOf(await sender.getAddress())).eq(value);
      expect(await mockToken.balanceOf(await alice.getAddress())).eq(
        ethers.parseUnits("900", 18)
      );
      const transfer = await sender.getTransfer(extId);
      // console.log({transfer});
      expect(tx)
        .to.emit(await sender.getAddress(), "Queued")
        .withArgs(extId, transfer, encodedDst, encodedMsg);
    });
  });
});

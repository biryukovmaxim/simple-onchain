// scripts/createTransferPermitted.ts
import { ethers } from "hardhat";
import {
  CallWithSyncFeeERC2771Request,
  GelatoRelay,
} from "@gelatonetwork/relay-sdk";
import { GaslessSender } from "../typechain-types";

async function main() {
  const [caller] = await ethers.getSigners();
  // get your GaslessSender contract
  const GaslessSender = await ethers.getContractFactory("GaslessSender");
  const gaslessSender = GaslessSender.attach(
    process.env.GASLESS_SENDER!
  ) as GaslessSender;

  const provider = new ethers.JsonRpcProvider(
    "https://rpc.ankr.com/arbitrum/76e1e00748fd6e2967a12424c64281015904fcf2a37f36c46dbec41814bd1548"
  );
  gaslessSender.connect(provider);

  const value = ethers.parseUnits("1", 6);

  const transferTx = await gaslessSender.transfer.populateTransaction(
    '0x2812946C6Efc4Cd6eE6EE171347D8C43B4221323',
    value
  );

  const relay = new GelatoRelay();
  const request: CallWithSyncFeeERC2771Request = {
    user: caller.address,
    chainId: 42161n,
    target: await gaslessSender.getAddress(),
    data: transferTx.data,
    feeToken: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    isRelayContext: true,
  };

  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
  // @ts-ignore
  const response = await relay.callWithSyncFeeERC2771(request, wallet);
  console.log({ response });
}

// Required for running via `hardhat run <script>`
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

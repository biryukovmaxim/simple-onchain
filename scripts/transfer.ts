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
    "https://endpoints.omniatech.io/v1/arbitrum/one/public"
  );
  gaslessSender.connect(provider);

  const value = ethers.parseUnits("2", 6);

  const approveTx = await gaslessSender.approve.populateTransaction(
    caller.address,
    value
  );

  const relay = new GelatoRelay();
  const approveRequest: CallWithSyncFeeERC2771Request = {
    user: caller.address,
    chainId: 42161n,
    target: await gaslessSender.getAddress(),
    data: approveTx.data,
    feeToken: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    isRelayContext: true,
  };

  const wallet = new ethers.Wallet(process.env.PRIVATE_KEY!, provider);
  // @ts-ignore
  let response = await relay.callWithSyncFeeERC2771(approveRequest, wallet);
  console.log({ response });
  await new Promise((r) => setTimeout(r, 5000));

  const transferTx = await gaslessSender.transfer.populateTransaction(
    "0x8389EBC35351D72280C7dF476B5A6c73393FC6BF",
    value
  );

  const transferRequest: CallWithSyncFeeERC2771Request = {
    user: caller.address,
    chainId: 42161n,
    target: await gaslessSender.getAddress(),
    data: transferTx.data,
    feeToken: "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE",
    isRelayContext: true,
  };

  // @ts-ignore
  response = await relay.callWithSyncFeeERC2771(transferRequest, wallet);
  console.log({ response });
}

// Required for running via `hardhat run <script>`
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

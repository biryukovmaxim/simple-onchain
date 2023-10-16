// scripts/createTransferPermitted.ts
import { ethers } from "hardhat";
import {
    CallWithSyncFeeERC2771Request,
    GelatoRelay,
} from "@gelatonetwork/relay-sdk";
import { GaslessSender } from "../typechain-types";
import { MockToken } from "../typechain-types";
import { UuidTool } from "uuid-tool";

async function main() {
    const [caller] = await ethers.getSigners();
    // get your GaslessSender contract
    const GaslessSender = await ethers.getContractFactory("GaslessSender");
    const gaslessSender = GaslessSender.attach(
        process.env.GASLESS_SENDER!
    ) as GaslessSender;
    const ERC20Permit = await ethers.getContractFactory("MockToken");
    const USD = ERC20Permit.attach(process.env.TOKEN!) as MockToken;

    // Prepare the permit signature
    const nonce = await USD.nonces(caller.address);
    const deadline = Math.floor(Date.now() / 1000) + 60 * 60; // 1 hour from now
    const value = ethers.parseUnits("1", 6);

    // set the domain parameters
    const domain = {
        name: await USD.name(),
        version: "1",
        chainId: 42161,
        verifyingContract: await USD.getAddress(),
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
        owner: caller.address,
        spender: await gaslessSender.getAddress(),
        value: value,
        nonce: nonce,
        deadline: deadline,
    };

    // sign the Permit type data with the deployer's private key
    const signature = await caller.signTypedData(domain, types, values);
    const sig = ethers.Signature.from(signature);
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL!);
    gaslessSender.connect(provider);

    const tx = await gaslessSender.transferFromPermitted.populateTransaction(
        "0xbc9016cBbA36eb51213d992aF0B89207Ae787D6C",
        value,
        deadline,
        sig.v,
        sig.r,
        sig.s,
    );

    const relay = new GelatoRelay();
    const request: CallWithSyncFeeERC2771Request = {
        user: caller.address,
        chainId: 42161n,
        target: await gaslessSender.getAddress(),
        data: tx.data,
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

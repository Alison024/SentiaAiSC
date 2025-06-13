import { ethers, hardhatArguments, network } from "hardhat";
import { expect } from "chai";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";
import {
  takeSnapshot,
  SnapshotRestorer,
  time,
} from "@nomicfoundation/hardhat-network-helpers";
import {
  PaymentCheck,
  PaymentCheck__factory,
  MockErc20,
  MockErc20__factory,
} from "../typechain-types";
import {
  ContractTransactionReceipt,
  ContractTransactionResponse,
  TransactionReceipt,
} from "ethers";
let owner: SignerWithAddress;
let user1: SignerWithAddress;
let PaymentFactory: PaymentCheck__factory;
let payment: PaymentCheck;
let MockErc20Factory: MockErc20__factory;
let mockErc: MockErc20;
let startSnapshot: SnapshotRestorer;

let pricePerMonth: bigint;
const MONTH = 60 * 60 * 24 * 30;
describe("PaymentCheck", async () => {
  before(async () => {
    [owner, user1] = await ethers.getSigners();
    PaymentFactory = (await ethers.getContractFactory(
      "PaymentCheck"
    )) as PaymentCheck__factory;
    MockErc20Factory = (await ethers.getContractFactory(
      "MockErc20"
    )) as MockErc20__factory;

    pricePerMonth = ethers.parseEther("0.001");
    payment = await PaymentFactory.deploy(ethers.ZeroAddress, pricePerMonth);
    mockErc = await MockErc20Factory.deploy();
    await mockErc.mint(owner.address, ethers.parseEther("1000000"));
    startSnapshot = await takeSnapshot();
  });
  afterEach(async () => {
    await startSnapshot.restore();
  });
  it("Must must deposit price per month correctly", async () => {
    await payment.deposit(0, { value: pricePerMonth });
    expect(await ethers.provider.getBalance(payment.target)).to.be.equal(
      pricePerMonth
    );
    expect(await payment.isUserValid(owner.address)).to.be.true;
    await time.increase(MONTH);
    expect(await payment.isUserValid(owner.address)).to.be.false;
  });
  it("Must must deposit price per 3 months correctly", async () => {});
});

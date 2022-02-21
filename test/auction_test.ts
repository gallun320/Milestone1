import { expect } from "chai";
import { ethers } from "hardhat";

describe("ERC20WithAuction", function () {
  it("Should deployed contract with 100 initial supply", async function () {
    const ERC20WithAuction = await ethers.getContractFactory("ERC20WithAuction");
    const token = await ERC20WithAuction.deploy(100, 30);
    await token.deployed();

    const [owner] = await ethers.getSigners();

    expect(await token.balanceOf(owner.address)).to.equal(100);
  });

  it("Should start voting and vote for price", async function () {
    const ERC20WithAuction = await ethers.getContractFactory("ERC20WithAuction");
    const token = await ERC20WithAuction.deploy(100, 30);
    await token.deployed();

    const [owner, account1] = await ethers.getSigners();

    expect(await token.balanceOf(owner.address)).to.equal(100);

    const transferTx = await token.connect(owner).transfer(account1.address, 5);

    await transferTx.wait();

    expect(await token.balanceOf(account1.address)).to.equal(5);

    const startVoteTx = await token.connect(account1).startVoting();

    await startVoteTx.wait();

    const voteTx = await token.connect(account1).vote(1);

    await voteTx.wait();

    expect(await token.auctionPrice()).to.equal(1);
  });

  it("Should voting than buy and sell", async function() {
    const ERC20WithAuction = await ethers.getContractFactory("ERC20WithAuction");
    const token = await ERC20WithAuction.deploy(100, 30);
    await token.deployed();

    const [owner, account1] = await ethers.getSigners();

    expect(await token.balanceOf(owner.address)).to.equal(100);

    const transferTx = await token.connect(owner).transfer(account1.address, 5);

    await transferTx.wait();

    expect(await token.balanceOf(account1.address)).to.equal(5);

    const startVoteTx = await token.connect(account1).startVoting();

    await startVoteTx.wait();

    const voteTx = await token.connect(account1).vote(1);

    await voteTx.wait();

    expect(await token.auctionPrice()).to.equal(1);

    const voteEndTx = await token.connect(account1).endVoting();

    await voteEndTx.wait();

    expect(await token.currentPrice()).to.equal(1);

    const options = {value: ethers.utils.parseEther("1.0")}
    const buyTx = await token.connect(account1).buy(5, options);

    await buyTx.wait();

    expect(await token.balanceOf(account1.address)).to.equal(10);

    const sellTx = await token.connect(account1).sell(5);

    await sellTx.wait();

    expect(await token.balanceOf(account1.address)).to.equal(5);
  });
});
import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";
import { ethers } from "hardhat";

describe("Facility", function () {
  async function deployFacilityFixture() {
    const [firstGuard, secondGuard, person1, person2, newGuard1, newGuard2] = await ethers.getSigners();

    const Facility = await hre.ethers.getContractFactory("Facility");
    const facility = await Facility.deploy(firstGuard, secondGuard);
    return { facility, firstGuard, secondGuard, person1, person2, newGuard1, newGuard2 };
  }

  describe("Deployment", function () {
    it("Should set the correct initial values", async function () {
      const { facility, firstGuard, secondGuard } = await loadFixture(deployFacilityFixture);

      //Check initial values
      expect(await facility.isDoorOpen()).to.be.false;
      expect(await facility.firstGuard()).to.equal(firstGuard.address);
      expect(await facility.secondGuard()).to.equal(secondGuard.address);
      expect(await facility.isChangingGuard()).to.be.false;
    });
  });

  describe("Entry", function () {
    it("Should allow entry when requested and approved by both guards", async function () {
      const { facility, firstGuard, secondGuard, person1 } = await loadFixture(deployFacilityFixture);

      //Request entry and approve by both guards
      await facility.connect(person1).requestEnter();
      await facility.connect(firstGuard).approveEnter(person1.address);
      await facility.connect(secondGuard).approveEnter(person1.address);

      //Check if the request was approved by both guards
      expect((await facility.requests(person1)).firstGuardApproved).to.equal(true);
      expect((await facility.requests(person1)).secondGuardApproved).to.equal(true);

      //Do entry by person1
      await facility.connect(person1).doEnter();

      //Check number of members in facility and requests should be empty after successful entry
      expect(await facility.checkIfMemberIsInside(person1.address)).to.be.true;
      expect((await facility.requests(person1)).firstGuardApproved).to.equal(false);
      expect((await facility.requests(person1)).secondGuardApproved).to.equal(false);

      //Checking logs
      const logs: string[] = await facility.getLogs();
      expect(logs.at(logs.length - 1)).to.equal(`Entered: ${person1.address.toLowerCase()}`); //Azért kell lower, mert a logban az address kisbetűs itt meg nagy lenne   

    });

    it("Should not allow entry without approval from both guards", async function () {
      const { facility, firstGuard, secondGuard, person1 } = await loadFixture(deployFacilityFixture);

      //Request entry and approve by only one guard
      await facility.connect(person1).requestEnter();
      await facility.connect(firstGuard).approveEnter(person1.address);

      //Check if the request was approved by only one guard
      expect((await facility.requests(person1)).firstGuardApproved).to.equal(true);
      expect((await facility.requests(person1)).secondGuardApproved).to.equal(false);

      //Do entry by person1 - should be reverted
      await expect(facility.connect(person1).doEnter()).to.be.revertedWith("Both guards must approve");
    });

    it("Should not allow entry if the facility is full", async function () {
      const { facility, firstGuard, secondGuard, person1, person2 } = await loadFixture(deployFacilityFixture);

      //Request an entry and approve by both guards to make the facility full
      await facility.connect(person1).requestEnter();
      await facility.connect(firstGuard).approveEnter(person1.address);
      await facility.connect(secondGuard).approveEnter(person1.address);
      await facility.connect(person1).doEnter();

      //Facility should be now full
      expect(await facility.isFacilityFull()).to.equal(true);

      //Request entry for the person2 and approve by both guards
      await facility.connect(person2).requestEnter();
      await facility.connect(firstGuard).approveEnter(person2.address);
      await facility.connect(secondGuard).approveEnter(person2.address);

      //Person2 entry should be reverted because the facility is full
      await expect(facility.connect(person2).doEnter()).to.be.revertedWith("Facility is full");

      //Facility should still should be full
      expect(await facility.isFacilityFull()).to.be.true;
    });
  });

  describe("Exit", function () {
    it("Should not allow guard on duty to exit", async function () {
      const { facility, firstGuard, secondGuard } = await loadFixture(deployFacilityFixture);

      //First guard tries to exit - should be reverted
      await facility.connect(firstGuard).requestExit();
      await expect(facility.connect(firstGuard).approveExit(firstGuard.address)).to.be.revertedWith("Guards on duty cannot exit");

      //Second guard tries to exit - should be reverted
      await facility.connect(secondGuard).requestExit();
      await expect(facility.connect(secondGuard).approveExit(secondGuard.address)).to.be.revertedWith("Guards on duty cannot exit");

    });

    it("Should allow exit when requested and approved by both guards", async function () {
      const { facility, firstGuard, secondGuard, person1 } = await loadFixture(deployFacilityFixture);

      //Request entry and approve by both guards
      await facility.connect(person1).requestEnter();
      await facility.connect(firstGuard).approveEnter(person1.address);
      await facility.connect(secondGuard).approveEnter(person1.address);
      await facility.connect(person1).doEnter();

      //Request exit and approve by both guards
      await facility.connect(person1).requestExit();
      await facility.connect(firstGuard).approveExit(person1.address);
      await facility.connect(secondGuard).approveExit(person1.address);

      //Facility should be full yet
      expect(await facility.isFacilityFull()).to.be.true;

      //Do exit by person1
      await facility.connect(person1).doExit(person1.address);

      //Facility should not be full and person1 should not be inside
      expect(await facility.isFacilityFull()).to.be.false;
      expect(await facility.checkIfMemberIsInside(person1.address)).to.be.false;

      //Checking logs
      const logs: string[] = await facility.getLogs();
      expect(logs.at(logs.length - 1)).to.equal(`Exited: ${person1.address.toLowerCase()}`);
    });

    it("Should not allow exit when not approved by both guards", async function () {
      const { facility, firstGuard, secondGuard, person1 } = await loadFixture(deployFacilityFixture);

      //Request entry and approve by both guards
      await facility.connect(person1).requestEnter();
      await facility.connect(firstGuard).approveEnter(person1.address);
      await facility.connect(secondGuard).approveEnter(person1.address);
      await facility.connect(person1).doEnter();

      //Request exit and approve only by one guard
      await facility.connect(person1).requestExit();
      await facility.connect(firstGuard).approveExit(person1.address);

      //Try exit by person1 
      await expect(facility.connect(person1).doExit(person1.address)).to.be.revertedWith("Both guards must approve");

      //Check number of members in facility
      expect(await facility.isFacilityFull()).to.be.true;
    });
  });

  describe("Changing guard", function () {
    it("Should change both guards", async function () {
      const { facility, firstGuard, secondGuard, newGuard1, newGuard2 } = await loadFixture(deployFacilityFixture);

      //Start changing guard
      await facility.connect(firstGuard).beginChangingGuard(newGuard1.address, newGuard2.address);

      expect(await facility.isChangingGuard()).to.be.true;
      expect(await facility.isFirstGuardChanged()).to.be.false;

      //First new guard enters
      await facility.connect(newGuard1).requestEnter();
      await facility.connect(firstGuard).approveEnter(newGuard1.address);
      await facility.connect(secondGuard).approveEnter(newGuard1.address);
      await facility.connect(newGuard1).doEnter();

      //First new guard takes the shift
      await facility.connect(newGuard1).acknowleChangeGuard();
      await facility.connect(firstGuard).acknowleChangeGuard();

      expect(await facility.firstGuard()).to.equal(newGuard1.address);

      //First old guard exits and completes the fist phase
      await facility.connect(firstGuard).requestExit();
      await facility.connect(newGuard1).approveExit(firstGuard.address);
      await facility.connect(secondGuard).approveExit(firstGuard.address);
      await facility.connect(firstGuard).doExit(firstGuard.address);

      expect(await facility.isFirstGuardChanged()).to.be.true;

      //Second new guard enters
      await facility.connect(newGuard2).requestEnter();
      await facility.connect(newGuard1).approveEnter(newGuard2.address);
      await facility.connect(secondGuard).approveEnter(newGuard2.address);
      await facility.connect(newGuard2).doEnter();

      //Second new guard takes the shift
      await facility.connect(newGuard2).acknowleChangeGuard();
      await facility.connect(secondGuard).acknowleChangeGuard();

      expect(await facility.firstGuard()).to.equal(newGuard1.address);
      expect(await facility.secondGuard()).to.equal(newGuard2.address);

      //Second old guard exits and completes the second phase
      await facility.connect(secondGuard).requestExit();
      await facility.connect(newGuard1).approveExit(secondGuard.address);
      await facility.connect(newGuard2).approveExit(secondGuard.address);
      await facility.connect(secondGuard).doExit(secondGuard.address);

      expect(await facility.isChangingGuard()).to.be.false;
    });

    it("Should not allow changing guards if the facility is full", async function () {
      const { facility, firstGuard, secondGuard, person1, newGuard1, newGuard2 } = await loadFixture(deployFacilityFixture);

      //Request an entry and approve by both guards to make the facility full
      await facility.connect(person1).requestEnter();
      await facility.connect(firstGuard).approveEnter(person1.address);
      await facility.connect(secondGuard).approveEnter(person1.address);
      await facility.connect(person1).doEnter();

      //Facility should be now full
      expect(await facility.isFacilityFull()).to.be.true;

      //Start changing guard - should be reverted
      await expect(facility.connect(firstGuard).beginChangingGuard(newGuard1.address, newGuard2.address)).to.be.revertedWith("Facility is full");
    });

    it("Should not allow entry during changing guard", async function () {
      const { facility, firstGuard, secondGuard, newGuard1, newGuard2, person1 } = await loadFixture(deployFacilityFixture);

      //Person1 gets approval to enter
      await facility.connect(person1).requestEnter();
      await facility.connect(firstGuard).approveEnter(person1.address);
      await facility.connect(secondGuard).approveEnter(person1.address);

      //Start changing guard
      await facility.connect(firstGuard).beginChangingGuard(newGuard1.address, newGuard2.address);

      //First new guard enters
      await facility.connect(newGuard1).requestEnter();
      await facility.connect(firstGuard).approveEnter(newGuard1.address);
      await facility.connect(secondGuard).approveEnter(newGuard1.address);
      await facility.connect(newGuard1).doEnter();

      //First new guard takes the shift
      await facility.connect(newGuard1).acknowleChangeGuard();
      await facility.connect(firstGuard).acknowleChangeGuard();

      //First old guard exits and completes the fist phase
      await facility.connect(firstGuard).requestExit();
      await facility.connect(newGuard1).approveExit(firstGuard.address);
      await facility.connect(secondGuard).approveExit(firstGuard.address);
      await facility.connect(firstGuard).doExit(firstGuard.address);

      //Person1 entry should be reverted because the facility is changing guard
      await expect(facility.connect(person1).doEnter()).to.be.revertedWith("Only new guards can enter during guard change");
    });

    it("Should only guard on duty begin changing guard", async function () {
      const { facility,firstGuard, person1, newGuard1, newGuard2 } = await loadFixture(deployFacilityFixture);

      //person1, newGuard1 tries to begin changing guard - should be reverted
      await expect(facility.connect(person1).beginChangingGuard(newGuard1.address, newGuard2.address)).to.be.revertedWith("Only guards can call this function");
      await expect(facility.connect(newGuard1).beginChangingGuard(newGuard1.address, newGuard2.address)).to.be.revertedWith("Only guards can call this function");
      expect(await facility.isChangingGuard()).to.be.false;

      //guard on duty can begin changing guard
      await expect(facility.connect(firstGuard).beginChangingGuard(newGuard1.address, newGuard2.address)).to.not.be.revertedWith("Only guards can call this function");
      expect(await facility.isChangingGuard()).to.be.true;
    });

  });

});

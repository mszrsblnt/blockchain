import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";
import { ethers } from "hardhat";

/*
 
- a belépést a két őr engedélyezi (mindkettően kötelezően)
- háromnál többen nem lehetnek a létesítményben
- sikeres belépés esetén a belépő őr naplózza a belépését
- sikeres kilépés esetén a kilépő őr naplózza a kilépését
- szolgálat alatt az őrök nem léphetnek ki a létesítményből
- őrség váltás:
  - új őr kérelmezi a belépést
  - két őr engedélyezi a belépést
  - új őr naplózza a belépést
  - szolgálat átadása megtörténik
  - régi őr kérelmezi a kilépést
  - két őr engedélyezi a kilépést
  - a kilépő őr naplózza a kilépést
  - ugyanez történik újra a másik őr váltása esetében is
 

  attributes:
  - isDoorOpen: boolean
  - firstGuard: address
  - secondGuard: address
  - membersInFacility: address[]
  - logs: string[]
  - isChangingGuard: boolean

  - membersWaitingToEnter: address[]
  - firstGuardApprovedEnter: map member:address => approved:boolean
  - secondGuardApprovedEnter: map member:address => approved:boolean
  
  - requests: map member:address => request: request
  - request struct:
      - member: address
      - isEnter: boolean
      - firstGuardApproved: boolean
      - secondGuardApproved: boolean
      

  methods:
  - requestEnter()
      - belépési kérelmet ad le, lementjük a msg.sender-t
  - approveEnter(member: address)
      - request msg.sender == firstGuard || secondGuard
      - jóváhagyja a belépést a firstGuard vagy a secondGuard
  - doEnter() - approved
      - siker esetén logol az msg.sender
      - requestsből töröl a belépési request
  - requestExit()
  - approveExit()
  - doExit() - approved 
  - changeGuard(address ?ezkell?, bool isFirstGuard) msg.sender-ben van az új őr
  
  modifiers:
  - approved function modifier() msg.sender-ben van az őr
      -> ha mindketten jóváhagyják, akkor beléphet

 
 
 */


describe("Facility", function () {
  async function deployFacilityFixture() {
    const [owner, firstGuard, secondGuard, person1, person2] = await ethers.getSigners();

    const Facility = await hre.ethers.getContractFactory("Facility");
    const facility = await Facility.deploy(firstGuard, secondGuard);
    return { facility, owner, firstGuard, secondGuard, person1, person2 };
  }

  describe("Deployment", function () {
    it("Should set the correct initial values", async function () {
      const { facility, owner, firstGuard, secondGuard } = await loadFixture(deployFacilityFixture);

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
      expect(await facility.membersInFacilityNumber()).to.equal(3);
      expect((await facility.requests(person1)).firstGuardApproved).to.equal(false);
      expect((await facility.requests(person1)).secondGuardApproved).to.equal(false);

      //Checking logs
      const logs: string[] = await facility.getLogs();
      // logs.forEach(element => { //DEBUGHOZ
      //   console.log(element.toString());
      // });
      expect(logs.at(logs.length - 1)).to.equal("Entered: "); //TODO: itt kéne nézni ki volt a pali aki bement

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
      expect(await facility.membersInFacilityNumber()).to.equal(3);

      //Request entry for the person2 and approve by both guards
      await facility.connect(person2).requestEnter();
      await facility.connect(firstGuard).approveEnter(person2.address);
      await facility.connect(secondGuard).approveEnter(person2.address);
      
      //Person2 entry should be reverted because the facility is full
      await expect(facility.connect(person2).doEnter()).to.be.revertedWith("Facility is full");
  
      //Facility should still be full with 3 members
      expect(await facility.membersInFacilityNumber()).to.equal(3);
    });
  });

  describe("Exit", function () {
    it("Should do sth", async function () {
      const { facility, firstGuard, secondGuard } = await loadFixture(deployFacilityFixture);

    });
  });
 
});

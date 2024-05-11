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
    const [owner, firstGuard, secondGuard, somebody] = await ethers.getSigners();

    const Facility = await hre.ethers.getContractFactory("Facility");
    const facility = await Facility.deploy(firstGuard, secondGuard);
    return { facility, owner, firstGuard, secondGuard, somebody };
  }

  describe("Deployment", function () {
    it("Should set the correct initial values", async function () {
      const { facility, owner, firstGuard, secondGuard } = await loadFixture(deployFacilityFixture);

      expect(await facility.isDoorOpen()).to.be.false;
      expect(await facility.firstGuard()).to.equal(firstGuard.address);
      expect(await facility.secondGuard()).to.equal(secondGuard.address);
      expect(await facility.isChangingGuard()).to.be.false;
    });
  });

  describe("Entry", function () {
    it("Should allow entry when requested and approved by both guards", async function () {
      const { facility, firstGuard, secondGuard, somebody } = await loadFixture(deployFacilityFixture);

      await facility.connect(somebody).requestEnter();

      await facility.connect(firstGuard).approveEnter(somebody.address);
      expect((await facility.requests(somebody)).firstGuardApproved).to.equal(true);

      await facility.connect(secondGuard).approveEnter(somebody.address);
      expect((await facility.requests(somebody)).secondGuardApproved).to.equal(true);

      await facility.connect(somebody).doEnter();
      expect(await facility.membersInFacilityNumber()).to.equal(3);
      
      const logs: string[] = await facility.getLogs();
      // logs.forEach(element => { //DEBUGHOZ
      //   console.log(element.toString());
      // });
      expect(logs.at(logs.length-1)).to.equal("Entered: "); //TODO: itt kéne nézni ki volt a pali aki bement

    });
    
    //TODO: alabbiakat nem csinaltam még

    it("Should not allow entry without approval from both guards", async function () {
      const { facility, firstGuard } = await loadFixture(deployFacilityFixture);

      await facility.requestEnter();
      await facility.approveEnter(firstGuard.address);
  
    });

    it("Should not allow entry if the facility is full", async function () {
      const { facility, firstGuard, secondGuard } = await loadFixture(deployFacilityFixture);

      await facility.requestEnter();
      await facility.approveEnter(firstGuard.address);
      await facility.approveEnter(secondGuard.address);

      await facility.requestEnter();

      // expect(await facility.membersInFacility(0)).to.have.lengthOf(2);
      expect(await facility.isDoorOpen()).to.be.false;
    });
  });

  // Add more test cases for exit, guard change, etc.
});

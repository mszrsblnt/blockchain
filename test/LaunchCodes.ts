import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
  import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
  import { expect } from "chai";
  import hre from "hardhat";

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
  
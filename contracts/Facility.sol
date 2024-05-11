// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Facility {
    string[] private logs;

    bool public isDoorOpen;
    address public firstGuard;
    address public secondGuard; 
    uint public membersInFacilityNumber;

    bool public isChangingGuard;
    bool public isFirstGuardChanged; //Hogy tudjuk a váltás melyik fázisában vagyunk

    struct GuardChange {
        address newGuard;
        bool newGuardAcknowledged;
        bool currentGuardAcknowledged;
    }
    //Azért van így, hogy az új és a jelenlegi őr is el tudja érni a guardChange-et, solidity stack exchange-n találtam hasonlót
    //Ez ilyen két kulcsos mapping de ez a trükk, hogy egy tömbben tárolunk és különboző címekhez tudjuk ezeket mappelni
    mapping(address => uint) private guardChangesMapping;
    GuardChange[2] private guardChanges;

    struct Request { 
        bool isEnter;
        bool firstGuardApproved;
        bool secondGuardApproved;
    }

    mapping(address => Request) public requests;

    constructor(address _firstGuard, address _secondGuard) {
        firstGuard = _firstGuard;
        secondGuard = _secondGuard;
        isDoorOpen = false;
        isChangingGuard = false;
        membersInFacilityNumber = 2; 
    }

    modifier approved() {
        require(
            requests[msg.sender].firstGuardApproved &&
                requests[msg.sender].secondGuardApproved,
            "Both guards must approve"
        );
        _;
    }

    modifier onlyGuard() {
        require(
            msg.sender == firstGuard || msg.sender == secondGuard,
            "Only guards can call this function"
        );
        _;
    }

    function requestEnter() external {
        requests[msg.sender] = Request(true, false, false);
    }

    function approveEnter(address member) external onlyGuard {
        require(requests[member].isEnter, "Member not waiting to enter"); 

        if (msg.sender == firstGuard) {
            requests[member].firstGuardApproved = true;
        } else if(msg.sender == secondGuard) {
            requests[member].secondGuardApproved = true;
        }
    }

    function doEnter() external approved {
        require(membersInFacilityNumber < 3, "Facility is full");

        //Igazából nem kéne mert nem is tud kimenni de a feladat kéri
        //Azt nem tudom, hogy itt vagy az approveban érdemesebb-e nézni
        require(
            msg.sender != firstGuard &&  msg.sender != secondGuard,
            "Guards on duty cannot enter"
        );

        //Ne tudjon más bemenni, ha éppen őrváltás van. Nehogy valaki bejusson a két őr között, akinek még éppen van jogosultsága
        if(isChangingGuard){
            require(guardChanges[guardChangesMapping[msg.sender]].newGuard == msg.sender, "Only new guards can enter during guard change");
        }

        isDoorOpen = true; 
        membersInFacilityNumber++;
        isDoorOpen = false;
        delete requests[msg.sender];
        
        string memory message = string(abi.encodePacked("Entered: "));  //TODO: valamiért nem működik a string(abi.encodePacked("Entered: ", member))
        logs.push(message); 
    }

    function requestExit() external {
        requests[msg.sender] = Request(false, false, false);
    }

    function approveExit(address member) external onlyGuard {
        require(!requests[member].isEnter, "Member not waiting to exit");
        require(
            member != firstGuard && member != secondGuard,
            "Guards on duty cannot exit"
        );

        if (msg.sender == firstGuard) {
            requests[member].firstGuardApproved = true;
        } else {
            requests[member].secondGuardApproved = true;
        }
    }

    function doExit(address member) external approved {
        //Kérdés: amíg nincs átadva a szolgálat az új őr kimehet?
        isDoorOpen = true; 
        membersInFacilityNumber--;
        isDoorOpen = false;
        delete requests[member];
        string memory message = string(abi.encodePacked("Exited: ")); //TODO: valamiért nem működik a string(abi.encodePacked("Exited: ", member))

        if(isChangingGuard){
            if(!isFirstGuardChanged){
                isFirstGuardChanged = true;
            } else {
                isChangingGuard = false;
            }
        }

        logs.push(message); 
    }
 
    function getLogs() external view returns (string[] memory) {
        return logs;
    }

    function beginChangingGuard(address _newGuard1, address _newGuard2) external  { //TODO: ezt kik hívhatják? Mert jelenleg bárki
        require(membersInFacilityNumber < 3, "Facility is full");
        isChangingGuard = true;
        isFirstGuardChanged = false;
        guardChanges[0] = GuardChange(_newGuard1, false, false);
        guardChanges[1] = GuardChange(_newGuard2, false, false);
        guardChangesMapping[_newGuard1] = 0;   
        guardChangesMapping[_newGuard2] = 1;
        guardChangesMapping[firstGuard] = 0;
        guardChangesMapping[secondGuard] = 1;
    }

    function acknowleChangeGuard() external {
        require(isChangingGuard, "Changing guard is not in progress");
        require(
            msg.sender == firstGuard || msg.sender == secondGuard || guardChanges[guardChangesMapping[msg.sender]].newGuard == msg.sender,
            "Only current or new guards can acknowledge guard change"
        );

        if(!isFirstGuardChanged){
            if(checkAcnknowledges(msg.sender, firstGuard)){
                firstGuard = guardChanges[guardChangesMapping[firstGuard]].newGuard;
            }
        } 
        else {
            if(checkAcnknowledges(msg.sender, secondGuard)){
                secondGuard = guardChanges[guardChangesMapping[secondGuard]].newGuard;
            }
        }
    }

    function checkAcnknowledges(address _sender, address currentGuard) internal returns (bool){
        if(guardChanges[guardChangesMapping[_sender]].newGuard == _sender){
            guardChanges[guardChangesMapping[_sender]].newGuardAcknowledged = true;
        } else if(_sender == currentGuard){
            guardChanges[guardChangesMapping[_sender]].currentGuardAcknowledged = true;
        }

        if(guardChanges[guardChangesMapping[currentGuard]].newGuardAcknowledged && guardChanges[guardChangesMapping[currentGuard]].currentGuardAcknowledged ){
            return true;
        } else {
            return false;
        }
    }

}

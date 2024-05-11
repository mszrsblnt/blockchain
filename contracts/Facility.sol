// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Facility {
    string[] private logs;

    bool public isDoorOpen;
    address public firstGuard;
    address public secondGuard; 
    uint public membersInFacilityNumber;
    bool public isChangingGuard;

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
        isDoorOpen = true; 
        membersInFacilityNumber--;
        isDoorOpen = false;
        delete requests[member];

        string memory message = string(abi.encodePacked("Exited: ")); //TODO: valamiért nem működik a string(abi.encodePacked("Exited: ", member))
        logs.push(message); 
    }
 
    function getLogs() external view returns (string[] memory) {
        return logs;
    }
}

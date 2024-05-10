// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Facility {
    bool public isDoorOpen;
    address public firstGuard;
    address public secondGuard;
    address[] public membersInFacility;
    string[] public logs;
    bool public isChangingGuard;

    struct Request {
        address member;
        bool isEnter;
        bool firstGuardApproved;
        bool secondGuardApproved;
    }

    mapping(address => Request) public requests;

     constructor(address _firstGuard, address _secondGuard) {
        firstGuard = _firstGuard;
        secondGuard = _secondGuard;
    }

    modifier approved() {
        require(
            requests[msg.sender].firstGuardApproved && requests[msg.sender].secondGuardApproved,
            "Both guards must approve"
        );
        _;
    }

    modifier onlyGuard() {
        require(msg.sender == firstGuard || msg.sender == secondGuard, "Only guards can call this function");
        _;
    }

    function requestEnter() external {
        requests[msg.sender] = Request(msg.sender, true, false, false);
    }

    function approveEnter(address member) external onlyGuard {
        require(requests[member].isEnter, "Member not waiting to enter");
        require(membersInFacility.length == 3, "Facility is full");

        if (msg.sender == firstGuard) {
           requests[member].firstGuardApproved = true;
        } else {
            requests[member].secondGuardApproved = true;
        }
    }

    function doEnter(address member) external approved {
        isDoorOpen = true;
        membersInFacility.push(member);
        isDoorOpen = false;
        delete requests[member];
        logs.push(string(abi.encodePacked("Entered: ", member)));
    }

    function requestExit() external {
        requests[msg.sender] = Request(msg.sender, false, false, false);
    }

    function approveExit(address member) external onlyGuard {
        require(!requests[member].isEnter, "Member not waiting to exit");
        require(member != firstGuard && member != secondGuard, "Guards on duty cannot exit");

        if (msg.sender == firstGuard) {
           requests[member].firstGuardApproved = true;
        } else {
            requests[member].secondGuardApproved = true;
        }
    }

    function doExit(address member) external approved {
        isDoorOpen = true;
        removeMember(member);
        isDoorOpen = false;
        delete requests[member];
        logs.push(string(abi.encodePacked("Exited: ", member)));
    }

    //segédfüggvény, a solidity nem tud simán törölni tetszőleges egy elemet egy tömbből
    function removeMember(address member) public {
        uint index = 0;
        while (index < membersInFacility.length && membersInFacility[index] != member) {
            index++;
        }

        if (index < membersInFacility.length) {
            // Move the last element into the place of the one to delete
            membersInFacility[index] = membersInFacility[membersInFacility.length-1];
            // Remove the last element
            membersInFacility.pop();
        }
    }
   
}

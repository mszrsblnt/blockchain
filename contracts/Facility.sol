// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Facility {
    bool public isDoorOpen;
    address public firstGuard;
    address public secondGuard;
    // address[] public membersInFacility; 
    uint public membersInFacilityNumber; //TODO: nem elég csak ez?
    string[] public logs;
    bool public isChangingGuard;

    struct Request {
        // address member; //nem kell, mert a requests mapping kulcsa az address
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
        //membersInFacility = new address[](3); 
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

    //TODO: lehet inkabb nem kene listan adni kiknek adtak, mindig max 1-nek kene engedely ki/bemenesre, kulonbden ha soknak adnak, de nem hajtják végre a doentert, de késobb igen akkor tobben is lehetnek mint 3 mert ott mar nem ellenorzunk.
    //TODO: vagy inkabb a doEnternel kene vizsgalni hogy tele van e, jogot meg lehet adni tobb embernek is
    function approveEnter(address member) external onlyGuard {
        require(requests[member].isEnter, "Member not waiting to enter");
        // require(membersInFacility.length < 3, "Facility is full");
        require(membersInFacilityNumber < 3, "Facility is full");

        if (msg.sender == firstGuard) {
            requests[member].firstGuardApproved = true;
        } else {
            requests[member].secondGuardApproved = true;
        }
    }

    function doEnter() external approved {
        isDoorOpen = true;
        // membersInFacility.push(msg.sender);
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
        // removeMember(member);
        membersInFacilityNumber--;
        isDoorOpen = false;
        delete requests[member];

        string memory message = string(abi.encodePacked("Exited: ")); //TODO: valamiért nem működik a string(abi.encodePacked("Exited: ", member))
        logs.push(message); 
    }

    //segédfüggvény, a solidity nem tud simán törölni tetszőleges egy elemet egy tömbből
    // function removeMember(address member) private {
    //     uint index = 0;
    //     while (
    //         index < membersInFacility.length &&
    //         membersInFacility[index] != member
    //     ) {
    //         index++;
    //     }

    //     if (index < membersInFacility.length) {
    //         // Move the last element into the place of the one to delete
    //         membersInFacility[index] = membersInFacility[
    //             membersInFacility.length - 1
    //         ];
    //         // Remove the last element
    //         membersInFacility.pop();
    //     }
    // }

    // function getMembersInFacilityNumber() external view returns (uint) {
    //     return membersInFacility.length;
    // }

    function getLogs() external view returns (string[] memory) {
        return logs;
    }
}

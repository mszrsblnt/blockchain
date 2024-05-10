// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Facility {
    bool public isDoorOpen;
    address public firstGuard;
    address public secondGuard;
    address[] public membersInFacility;
    string[] public logs;
    bool public isChangingGuard;

    mapping(address => bool) public membersWaitingToEnter;
    mapping(address => mapping(address => bool)) public firstGuardApprovedEnter;
    mapping(address => mapping(address => bool)) public secondGuardApprovedEnter;

    struct Request {
        address member;
        bool isEnter;
        bool firstGuardApproved;
        bool secondGuardApproved;
    }

    mapping(address => Request) public requests;

    modifier approved() {
        require(
            firstGuardApprovedEnter[msg.sender][msg.sender] && secondGuardApprovedEnter[msg.sender][msg.sender],
            "Both guards must approve"
        );
        _;
    }

    modifier onlyGuard() {
        require(msg.sender == firstGuard || msg.sender == secondGuard, "Only guards can call this function");
        _;
    }

    constructor(address _firstGuard, address _secondGuard) {
        firstGuard = _firstGuard;
        secondGuard = _secondGuard;
    }

    function requestEnter() external {
        require(!isChangingGuard, "Guard changing is in progress");
        require(membersInFacility.length < 3, "Facility is full");
        require(!membersWaitingToEnter[msg.sender], "Already waiting to enter");
        require(!requests[msg.sender].isEnter, "Already requested to enter");

        membersWaitingToEnter[msg.sender] = true;
        requests[msg.sender] = Request(msg.sender, true, false, false);
    }

    function approveEnter(address member) external onlyGuard {
        require(membersWaitingToEnter[member], "Member not waiting to enter");
        require(!firstGuardApprovedEnter[member][msg.sender], "Already approved by first guard");
        require(!secondGuardApprovedEnter[member][msg.sender], "Already approved by second guard");

        if (msg.sender == firstGuard) {
            firstGuardApprovedEnter[member][msg.sender] = true;
        } else {
            secondGuardApprovedEnter[member][msg.sender] = true;
        }

        if (firstGuardApprovedEnter[member][msg.sender] && secondGuardApprovedEnter[member][msg.sender]) {
            _doEnter(member);
        }
    }

    function _doEnter(address member) private approved() {
        isDoorOpen = true;
        membersInFacility.push(member);
        logs.push(string(abi.encodePacked("Entered: ", member)));
        delete membersWaitingToEnter[member];
        delete requests[member];
    }

    function requestExit() external {
        require(isDoorOpen, "Door is closed");
        require(!isChangingGuard, "Guard changing is in progress");
        require(membersInFacility.length > 0, "No members in facility");
        require(membersInFacility[membersInFacility.length - 1] == msg.sender, "Only last member can exit");
        require(!requests[msg.sender].isEnter, "Already requested to enter");

        requests[msg.sender] = Request(msg.sender, false, false, false);
    }

    function approveExit() external {
        require(msg.sender == firstGuard || msg.sender == secondGuard, "Only guards can approve");
        require(requests[msg.sender].member == msg.sender, "Member not waiting to exit");
        require(!firstGuardApprovedEnter[msg.sender][msg.sender], "Already approved by first guard");
        require(!secondGuardApprovedEnter[msg.sender][msg.sender], "Already approved by second guard");

        if (msg.sender == firstGuard) {
            firstGuardApprovedEnter[msg.sender][msg.sender] = true;
        } else {
            secondGuardApprovedEnter[msg.sender][msg.sender] = true;
        }

        if (firstGuardApprovedEnter[msg.sender][msg.sender] && secondGuardApprovedEnter[msg.sender][msg.sender]) {
            _doExit(msg.sender);
        }
    }

    function _doExit(address member) private approved() {
        isDoorOpen = false;
        for (uint256 i = 0; i < membersInFacility.length; i++) {
            if (membersInFacility[i] == member) {
                membersInFacility[i] = address(0);
                break;
            }
        }
        logs.push(string(abi.encodePacked("Exited: ", member)));
        delete requests[member];
    }

    function changeGuard(address newGuard, bool isFirstGuard) external {
        require(!isChangingGuard, "Guard changing is in progress");
        isChangingGuard = true;

        if (isFirstGuard) {
            firstGuard = newGuard;
        } else {
            secondGuard = newGuard;
        }

        isChangingGuard = false;
    }


}
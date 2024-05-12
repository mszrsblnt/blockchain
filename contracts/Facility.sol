// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Facility {
    uint public constant MAX_INSIDE = 3;
    string[] private logs;

    bool public isDoorOpen;
    address public firstGuard;
    address public secondGuard;
    address[] public membersInside;

    bool public isChangingGuard;
    bool public isFirstGuardChanged; //Hogy tudjuk a váltás melyik fázisában vagyunk

    struct GuardChange {
        address newGuard;
        bool newGuardAcknowledged;
        bool currentGuardAcknowledged;
    }
    //Azért van így, hogy az új és a jelenlegi őr is el tudja érni a guardChange-et, solidity stack exchange-n találtam hasonlókat
    //Két kulcsos mapping:egy tömbben tárolunk és különboző címekhez tudjuk ugyanazokat inedexeket mappelni
    mapping(address => uint) private guardChangesMapping;
    GuardChange[2] private guardChanges;

    struct Request {
        bool isEnter;
        bool firstGuardApproved;
        bool secondGuardApproved;
    }

    mapping(address => Request) public requests;

    event DoorOpened(); //Esemény, ha az ajtó kinyilik

    constructor(address _firstGuard, address _secondGuard) {
        firstGuard = _firstGuard;
        secondGuard = _secondGuard;
        membersInside.push(firstGuard);
        membersInside.push(secondGuard);
        isDoorOpen = false;
        isChangingGuard = false;
    }

    //Csak akkor hívható meg, ha mindkét őr jóváhagyta
    modifier approved() {
        require(
            requests[msg.sender].firstGuardApproved &&
                requests[msg.sender].secondGuardApproved,
            "Both guards must approve"
        );
        _;
    }

    //Csak az őrök hívhatják meg
    modifier onlyGuard() {
        require(
            msg.sender == firstGuard || msg.sender == secondGuard,
            "Only guards can call this function"
        );
        _;
    }

    //Csak azok hívhatják meg, akik bent vannak
    modifier onlyMembersInside() {
        bool isInside = checkIfMemberIsInside(msg.sender);
        require(isInside, "Only members inside can call this function");
        _;
    }

    //Csak azok hívhatják meg, akik nincsenek bent
    modifier onlyMembersOutside() {
        bool isInside = checkIfMemberIsInside(msg.sender);
        require(!isInside, "Only members outside can call this function");
        _;
    }

    //Megnézi hogy az adott ember bent van-e a facilityben
    function checkIfMemberIsInside(address member) public view returns (bool) {
        for (uint i = 0; i < membersInside.length; i++) {
            if (membersInside[i] == member) {
                return true;
            }
        }
        return false;
    }

    //Belépési kérelem hozzáadása a küldő azonosítójával
    function requestEnter() external onlyMembersOutside {
        requests[msg.sender] = Request(true, false, false);
    }

    //Az őrök hívhatják meg, hogy jóváhagyják a belépést
    function approveEnter(address member) external onlyGuard {
        require(requests[member].isEnter, "Member not waiting to enter");

        if (msg.sender == firstGuard) {
            requests[member].firstGuardApproved = true;
        } else if (msg.sender == secondGuard) {
            requests[member].secondGuardApproved = true;
        }
    }

    //Belépés végrehajtása, ha az ember kint van és mindkét őr jóváhagyta
    function doEnter() external approved onlyMembersOutside {
        require(membersInside.length < MAX_INSIDE, "Facility is full");

        //Ne tudjon más bemenni, ha éppen őrváltás van. Nehogy valaki bejusson a két őr között, akinek még éppen van jogosultsága
        if (isChangingGuard) {
            require(
                getGuardChange(msg.sender).newGuard == msg.sender,
                "Only new guards can enter during guard change"
            );
        }

        isDoorOpen = true;
        emit DoorOpened();
        membersInside.push(msg.sender); 
        isDoorOpen = false;
        delete requests[msg.sender];

        string memory message = string.concat(
            "Entered: ",
            toAsciiString(msg.sender)
        );
        logs.push(message);
    }

    //Kilépési kérelem hozzáadása a küldő azonosítójával
    function requestExit() external onlyMembersInside {
        requests[msg.sender] = Request(false, false, false);
    }

    //Az őrök hívhatják meg, hogy jóváhagyják a kilépést
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

    //Kilépés végrehajtása, ha az ember bent van és mindkét őr jóváhagyta
    function doExit(address member) external approved onlyMembersInside {
        if (isChangingGuard) {
            require(
                getGuardChange(msg.sender).newGuard != msg.sender,
                "New guards cannot exit during guard change"
            );
        }

        isDoorOpen = true;
        emit DoorOpened();
        removeFromMembersInside(member);
        isDoorOpen = false;
        delete requests[member];
        string memory message = string.concat(
            "Exited: ",
            toAsciiString(member)
        );

        if (isChangingGuard) {
            if (!isFirstGuardChanged) {
                isFirstGuardChanged = true;
            } else {
                isChangingGuard = false;
            }
        }

        logs.push(message);
    }

    //Az összes log lekérdezése
    function getLogs() external view returns (string[] memory) {
        return logs;
    }

    //Őrváltás kezdeményezése, csak a jelenlegi őrök hívhatják meg
    function beginChangingGuard(
        address _newGuard1,
        address _newGuard2
    ) external onlyGuard {
        require(membersInside.length < MAX_INSIDE, "Facility is full");
        isChangingGuard = true;
        isFirstGuardChanged = false;
        guardChanges[0] = GuardChange(_newGuard1, false, false);
        guardChanges[1] = GuardChange(_newGuard2, false, false);
        guardChangesMapping[_newGuard1] = 0;
        guardChangesMapping[_newGuard2] = 1;
        guardChangesMapping[firstGuard] = 0;
        guardChangesMapping[secondGuard] = 1;
    }

    //Őrség átadása azzal, hogy a két őr kölcsonösen elismeri a váltást
    function acknowleChangeGuard() external {
        require(isChangingGuard, "Changing guard is not in progress");
        require(
            msg.sender == firstGuard ||
                msg.sender == secondGuard ||
                getGuardChange(msg.sender).newGuard == msg.sender,
            "Only current or new guards can acknowledge guard change"
        );

        if (!isFirstGuardChanged) {
            if (checkAcnknowledges(msg.sender, firstGuard)) {
                firstGuard = getGuardChange(firstGuard).newGuard;
            }
        } else {
            if (checkAcnknowledges(msg.sender, secondGuard)) {
                secondGuard = getGuardChange(secondGuard).newGuard;
            }
        }
    }

    //Az őrök kölcsonös elismerésének ellenőrzése
    function checkAcnknowledges(
        address _sender,
        address currentGuard
    ) internal returns (bool) {
        if (getGuardChange(msg.sender).newGuard == _sender) {
            getGuardChange(msg.sender).newGuardAcknowledged = true;
        } else if (msg.sender == currentGuard) {
            getGuardChange(msg.sender).currentGuardAcknowledged = true;
        }

        if (
            getGuardChange(currentGuard).newGuardAcknowledged &&
            getGuardChange(currentGuard).currentGuardAcknowledged
        ) {
            return true;
        } else {
            return false;
        }
    }

    //Az őrváltás adatainak lekérdezése
    function getGuardChange(
        address _sender
    ) private view returns (GuardChange storage) {
        return guardChanges[guardChangesMapping[_sender]];
    }

    //_address eltávolítása a membersInside-ból
    function removeFromMembersInside(address _address) internal {
        for (uint i = 0; i < membersInside.length; i++) {
            if (membersInside[i] == _address) {
                membersInside[i] = membersInside[membersInside.length - 1];
                membersInside.pop();
            }
        }
    }

    //Megnézi, hogy a facility tele van-e
    function isFacilityFull() external view returns (bool) {
        return membersInside.length == MAX_INSIDE;
    }

    //Az alábbi két segédfüggvény forrása: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2 ** (8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string.concat("0x", string(s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}

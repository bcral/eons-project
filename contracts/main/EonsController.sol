// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

import '../peripheries/utilities/Roles.sol';

contract EonsController is Ownable {
    using Roles for Roles.Role;

    Roles.Role private admin;

    bool private paused;

    constructor() {
        admin.add(msg.sender);
        paused = false;
    }

// ******************************* Pausable **********************************    

    function isPaused() public view returns(bool) {
        return paused;
    }

    modifier whenNotPaused() {
        require(!isPaused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(isPaused(), "Pausable: not paused");
        _;
    }

    function pause() external whenNotPaused onlyAdmin {
        paused = true;
    }

    function unPause() external whenPaused onlyAdmin {
        paused = false;
    }

// ***************************** Access Control *******************************  

    modifier onlyAdmin() {
        require(admin.has(msg.sender), "Only an admin can call this.");
        _;
    }

    function addAdmin(address _user) external onlyOwner {
        admin.add(_user);
    }

}
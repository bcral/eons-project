// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

import '../peripheries/interfaces/IEonsAaveVault.sol';
import '../peripheries/interfaces/IEonsAaveRouter.sol';

contract iEonsController is OwnableUpgradeable, AccessControlUpgradeable {

    bool private paused;
    bytes32 private constant admin = keccak256("ADMIN");

    function initialize() external {
        __Ownable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(admin, msg.sender);
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

    function pause() external whenNotPaused onlyRole(admin) {
        paused = true;
    }

    function unPause() external whenPaused onlyRole(admin) {
        paused = false;
    }

// ***************************** Access Control *******************************  

    function addAdmin(address _user) external onlyRole(admin) {
        grantRole(admin, _user);
    }

}
// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import "hardhat/console.sol";

import '../utilities/MinterRole.sol';

contract EonsLP is ERC20Upgradeable, OwnableUpgradeable, MinterRole {
    using SafeMathUpgradeable for uint;

    string private _name;

    function initialize() public initializer {
        __ERC20_init('EONS LP', 'ELP');
        __MinterRole_init();
        __Ownable_init();
    }

    /// @dev Mint ELP. Only minter can mint
    function mint(address recepient, uint amount) public onlyMinter {
        _mint(recepient, amount);
    }

    /// @dev Burn ELP from caller
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /// @dev Burn ALP from given account. Caller must have proper allowance.
    function burnFrom(address account, uint256 _amount) external {
        uint256 decreasedAllowance =
            allowance(account, _msgSender()).sub(_amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, _amount);
    }

    /**
     * @notice Transfer tokens to multiple recipient
     * @dev Left 160 bits are the recipient address and the right 96 bits are the token amount.
     * @param bits array of uint
     * @return true/false
     */
    function multiTransfer(uint256[] memory bits) external returns (bool) {
        for (uint256 i = 0; i < bits.length; i++) {
            address a = address(bits[i] >> 96);
            uint256 amount = bits[i] & ((1 << 96) - 1);
            require(transfer(a, amount), "Transfer failed");
        }
        return true;
    }
}

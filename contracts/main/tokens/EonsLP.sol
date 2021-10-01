// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "hardhat/console.sol";

import '../../peripheries/utilities/MinterRole.sol';

contract EonsLP is ERC20('EONS LP', 'ELP'), Ownable, MinterRole {

    /// @dev Mint ELP. Only minter can mint
    function mint(address recepient, uint amount) external onlyMinter {
        _mint(recepient, amount);
    }

    /// @dev Burn ELP from caller
    function burn(uint256 amount) external {
        _burn(_msgSender(), amount);
    }

    /// @dev Burn ALP from given account. Caller must have proper allowance.
    function burnFrom(address _account, uint256 _amount) external {
        uint256 decreasedAllowance =
            allowance(_account, _msgSender())-_amount;

        _approve(_account, _msgSender(), decreasedAllowance);
        _burn(_account, _amount);
    }

    /**
     * @notice Transfer tokens to multiple recipient
     * @dev Left 160 bits are the recipient address and the right 96 bits are the token amount.
     * @param bits array of uint
     * @return true/false
     */
    function multiTransfer(uint256[] memory bits) external returns (bool) {
        for (uint256 i = 0; i < bits.length; i++) {
            address a = address(uint160(uint256(bits[i] >> 96)));
            uint256 amount = bits[i] & ((1 << 96) - 1);
            require(transfer(a, amount), "Transfer failed");
        }
        return true;
    }
}

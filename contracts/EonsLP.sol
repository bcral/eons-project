// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract EonsLP is ERC20, Ownable {
    using SafeMath for uint;

    string private _name;
    // uint256 private INITIAL_MINT_SUPPLY = 10000000 * (10 ** 18);

    constructor() public ERC20("EonsLP", "ELP") {

    }

    /// @dev Mint ALP. Only owner can mint
    function mint(address recepient, uint _amount) public onlyOwner {
        require(totalSupply().add(_amount) <= INITIAL_MINT_SUPPLY, 'Minting now allowed');
        _mint(recepient, _amount);
    }

    /// @dev Burn ALP from caller
    function burn(uint256 _amount) external {
        _burn(_msgSender(), _amount);
    }

    /// @dev Burn ALP from given account. Caller must have proper allowance.
    function burnFrom(address _account, uint256 _amount) external {
        uint256 decreasedAllowance =
            allowance(_account, _msgSender()).sub(_amount, "ERC20: burn amount exceeds allowance");

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
            address a = address(bits[i] >> 96);
            uint256 amount = bits[i] & ((1 << 96) - 1);
            require(transfer(a, amount), "Transfer failed");
        }
        return true;
    }
}

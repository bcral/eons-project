// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import 'hardhat/console.sol';

import '../utilities/MinterRole.sol';

contract Eons is ERC20, Ownable, MinterRole {

  mapping (address => uint) _approvedMinter;
  uint private _transactionFee;
  address payable private _wallet;

  constructor() public ERC20('EONS Token', 'EONS') {
    _transactionFee = 5 * 10 ** 14;
    _wallet = payable(msg.sender);
  }

  function approvedAmountOfMinter(address minter) external view returns(uint amount) {
    amount = _approvedMinter[minter];
  }

  function getTransactionFee() external view returns (uint) {
    return _transactionFee;
  }

  function setWallet(address payable wallet) external onlyOwner {
    _wallet = wallet;
  }

  function setTransactionFee(uint transactionFee) external onlyOwner {
    _transactionFee = transactionFee;
  }

  /// @dev Mint EONS. Only minter can mint
  function mint(address recepient, uint amount) external onlyMinter {
    _mint(recepient, amount);
  }

  /// @dev allows address to mint ammount of EONS
  function mintApprove(address minter, uint amount) external onlyOwner {
    _approvedMinter[minter] = _approvedMinter[minter]+amount;
  }

  /// @dev mints amount of eons for only approaved users
  function mintForApprovedUser(uint amount) external payable {
    require(msg.value >= _transactionFee, 'Fee invalid');
    require(_approvedMinter[msg.sender] >= amount, 'exceeded amount to mint');
    
    _wallet.transfer(msg.value);
    _mint(msg.sender, amount);
    _approvedMinter[msg.sender] = _approvedMinter[msg.sender]-amount;
  }

  /// @dev Burn EONS from caller
  function burn(uint256 amount) external {
    _burn(_msgSender(), amount);
  }

  /// @dev Burn EONS from given account. Caller must have proper allowance.
  function burnFrom(address account, uint256 _amount) external {
    uint256 decreasedAllowance =
      allowance(account, _msgSender())-_amount;

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
      address a = address(uint160(uint256(bits[i] >> 96)));
      uint256 amount = bits[i] & ((1 << 96) - 1);
      require(transfer(a, amount), 'Transfer failed');
    }
    return true;
  }
}

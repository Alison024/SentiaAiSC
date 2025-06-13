// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MockErc20 is ERC20 {
    constructor() ERC20("Test token", "TT") {}
    function mint(address recipient, uint256 amount) external {
        _mint(recipient, amount);
    }
}

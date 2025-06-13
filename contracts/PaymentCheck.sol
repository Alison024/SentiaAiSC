// SPDX-License-Identifier: MIT
pragma solidity =0.8.28;
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
contract PaymentCheck is Ownable {
    using SafeERC20 for IERC20;

    error ZeroAddress();
    error ZeroValue();
    error InsufficientBalance();
    error NativeTransferFailed();
    error SmallDeposit();

    event Deposited(address indexed user, address token, uint256 amount);
    event UpdatedTokenSettings(address token, uint256 pricePerMonth);
    event Withdrawn(address token, uint256 amount);

    uint256 public constant MONTH = 60 * 60 * 24 * 30;
    uint256 public constant PRECISION = 1e18;
    address public token;
    uint256 public pricePerMonth;
    mapping(address => uint32) public subscriptionEnd;

    constructor(address _token, uint256 _pricePerMonth) Ownable(msg.sender) {
        _setTokenSettings(_token, _pricePerMonth);
    }

    function deposit(uint256 _amount) external payable {
        address tokenLocal = token;
        uint256 pricePerMonthLocal = pricePerMonth;
        if (tokenLocal == address(0)) {
            _amount = msg.value;
            if (_amount == 0) revert ZeroValue();
            if (_amount < pricePerMonthLocal) revert SmallDeposit();
        } else {
            if (_amount == 0) revert ZeroValue();
            if (_amount < pricePerMonthLocal) revert SmallDeposit();
            IERC20(tokenLocal).safeTransferFrom(
                msg.sender,
                address(this),
                _amount
            );
        }
        _storeDepositData(msg.sender, pricePerMonthLocal, _amount);
        emit Deposited(msg.sender, tokenLocal, _amount);
    }

    function withdraw(address _token, uint256 _amount) external onlyOwner {
        if (_token == address(0)) {
            _transferNative(payable(msg.sender), _amount);
        } else {
            IERC20(_token).safeTransfer(msg.sender, _amount);
        }
        emit Withdrawn(_token, _amount);
    }

    function setTokenSettings(
        address _token,
        uint256 _pricePerMonth
    ) external onlyOwner {
        _setTokenSettings(_token, _pricePerMonth);
    }

    function isUserValid(address _user) public view returns (bool) {
        return subscriptionEnd[_user] > uint32(block.timestamp);
    }

    function _storeDepositData(
        address _user,
        uint256 _pricePerMonth,
        uint256 _amount
    ) internal {
        uint32 subEnd = subscriptionEnd[_user];
        uint32 current = uint32(block.timestamp);
        uint32 toIncrease = uint32(
            ((_amount * PRECISION) / _pricePerMonth) / PRECISION
        );
        if (subEnd < current) {
            subscriptionEnd[_user] = current + toIncrease;
        } else {
            subscriptionEnd[_user] = subEnd + toIncrease;
        }
    }

    function _transferNative(
        address payable _recipient,
        uint256 _amount
    ) internal {
        if (_recipient == address(0)) revert ZeroAddress();
        if (_amount == 0) revert ZeroValue();
        if (address(this).balance < _amount) revert InsufficientBalance();
        (bool sent, ) = _recipient.call{value: _amount}("");
        if (!sent) revert NativeTransferFailed();
    }

    function _setTokenSettings(
        address _token,
        uint256 _pricePerMonth
    ) internal {
        if (_pricePerMonth == 0) revert ZeroValue();
        token = _token;
        pricePerMonth = _pricePerMonth;
        emit UpdatedTokenSettings(_token, _pricePerMonth);
    }
}

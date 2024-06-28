// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import {console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

interface IERC20 {
    // Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    // Returns the remaining number of tokens that `spender` will be
    // allowed to spend on behalf of `owner` through {transferFrom}. This is
    // zero by default.
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    // Sets `amount` as the allowance of `spender` over the caller's tokens.
    function approve(address spender, uint256 amount) external returns (bool);

    // Moves `amount` tokens from `sender` to `recipient` using the
    // allowance mechanism. `amount` is then deducted from the caller's
    // allowance.
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(address user, uint256 amount) external returns (bool);
}

contract AirdropT1 is ERC20, ERC20Permit, Ownable(msg.sender) {
    uint256 immutable TOTAL_SUPPLY;
    address immutable OWNER;

    constructor(
        uint256 _totalSupply
    ) ERC20("GuildAirdrop1", "GAA1") ERC20Permit("GuildAirdrop1") {
        require(msg.sender != address(0), "deployer address invalid");
        TOTAL_SUPPLY = _totalSupply;
        OWNER = msg.sender;
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function transferAirdropManagement(address _newOwner) public onlyOwner {
        transferOwnership(_newOwner);
        transfer(_newOwner, TOTAL_SUPPLY);
    }
}

contract AirdropT2 is ERC20, ERC20Permit, Ownable(msg.sender) {
    uint256 immutable TOTAL_SUPPLY;
    address immutable OWNER;

    constructor(
        uint256 _totalSupply
    ) ERC20("GuildAirdrop2", "GAA2") ERC20Permit("GuildAirdrop2") {
        require(msg.sender != address(0), "deployer address invalid");
        TOTAL_SUPPLY = _totalSupply;
        OWNER = msg.sender;
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    function transferAirdropManagement(address _newOwner) public onlyOwner {
        transferOwnership(_newOwner);
        transfer(_newOwner, TOTAL_SUPPLY);
    }
}

contract GuildAirdrop {
    IERC20 public drop1;
    IERC20 public drop2;
    bytes32 public DOMAIN_SEPARATOR;
    mapping(address user => int8 is_qualified) eligibility_status;
    mapping(address qualified => mapping(address _airdrop => address _claimedTo))
        internal claimedStatuses;

    struct Sig {
        address claimToAddress;
        address qualifiedAddress;
        address drop1Addr;
        address drop2Addr;
    }

    constructor(address _drop1, address _drop2, uint256 _chainId) {
        drop1 = IERC20(_drop1);
        drop2 = IERC20(_drop2);
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("GuildAirdrop Contract")), // Name of the app. Should this be a constructor param?
                keccak256(bytes("1")), // Version. Should this be a constructor param?
                _chainId, // Replace with actual chainId (Base Sepolia: 84532)
                address(this)
            )
        );
    }

    // function getTotalSupply() public returns(uint256){
    //     return TOTAL_SUPPLY;
    // }

    // only those who have checked their status can claim airdrop
    function checkEligibility(address _user) public returns (bool) {
        return _checkEligibility(_user);
    }

    function _checkEligibility(address _user) internal returns (bool) {
        if (_user.balance >= 1e9) {
            eligibility_status[_user] = 2;
            console.log("user is eligible", true);
            return true; //user is eligible
        } else {
            eligibility_status[_user] = 1;
            return false; //user NOT eligible
        }
    }

    function claimAirdrop1() public {
        if (
            eligibility_status[msg.sender] == 2 &&
            claimedStatuses[msg.sender][address(drop1)] == address(0)
        ) {
            claimedStatuses[msg.sender][address(drop1)] = msg.sender;
            drop1.transfer(msg.sender, 1e6);
            // require(success, "claimed both airdrops failed");
        }
    }

    function claimAirdrop2() public {
        if (
            eligibility_status[msg.sender] == 2 &&
            claimedStatuses[msg.sender][address(drop2)] == address(0)
        ) {
            claimedStatuses[msg.sender][address(drop2)] = msg.sender;
            drop2.transfer(msg.sender, 1e6);
            // require(success, "claimed both airdrops failed");
        }
    }

    function claimFirstAirdropToAnotherWallet(
        Sig calldata message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(
            message.claimToAddress != address(0),
            "you cannot claim to address zero"
        );
        if (
            eligibility_status[message.qualifiedAddress] == 2 &&
            (claimedStatuses[message.qualifiedAddress][address(drop1)] ==
                address(0))
        ) {
            //  require(block.timestamp <= message.deadline);
            bytes32 hashedMessage = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    _hashMessage(message)
                )
            );
            address recoveredAddress = ecrecover(hashedMessage, v, r, s);
            console.log("message signer=>", recoveredAddress);
            console.log("qualified account=>=>", message.qualifiedAddress);

            require(
                recoveredAddress == message.qualifiedAddress,
                "The eligible address must sign the claim message"
            );
            // balance[message.from] = balance[message.from] + message.amount;
            claimedStatuses[message.qualifiedAddress][address(drop1)] = message
                .claimToAddress;
            bool success = drop1.transfer(message.claimToAddress, 1e9);

            require(
                success,
                "Guild airdrop-1 claim to different wallet failed"
            );
        } else {
            revert("this wallet isn't eligible for the airdrop");
        }
    }

    function claimSecondAirdropToAnotherWallet(
        Sig calldata message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public // address user
    {
        require(
            message.claimToAddress != address(0),
            "you cannot claim to address zero"
        );
        if (
            eligibility_status[message.qualifiedAddress] == 2 &&
            (claimedStatuses[message.qualifiedAddress][address(drop2)] ==
                address(0))
        ) {
            //  require(block.timestamp <= message.deadline);
            bytes32 hashedMessage = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    _hashMessage(message)
                )
            );

            address recoveredAddress = ecrecover(hashedMessage, v, r, s);
            require(
                recoveredAddress == message.qualifiedAddress,
                "The eligible address must sign the claim message"
            );
            // balance[message.from] = balance[message.from] + message.amount;
            claimedStatuses[msg.sender][address(drop2)] = message
                .claimToAddress;
            bool success = drop2.transfer(message.claimToAddress, 1e6);

            require(
                success,
                "Guild airdrop-1 claim to different wallet failed"
            );
        } else {
            revert("this wallet isn't eligible for the airdrop");
        }
    }

    function _hashMessage(
        Sig calldata _message
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "Sig(address claimToAddress, address qualifiedAddress, address drop1Addr, address drop2Addr)"
                    ),
                    _message.claimToAddress,
                    _message.qualifiedAddress,
                    _message.drop1Addr,
                    _message.drop2Addr
                )
            );
    }

    function getDomainSeparator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }
}

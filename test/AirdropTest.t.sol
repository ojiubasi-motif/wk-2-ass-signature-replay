// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {AirdropT1, AirdropT2,GuildAirdrop} from "../src/AirdropSignature.sol";

contract AirdropTest is Test {
    AirdropT1 public drop1;
    AirdropT2 public drop2;
    GuildAirdrop public dropManager;

    uint256 user1Privatekey = uint256(keccak256("i qualified for the airdrops"));
    address user1 = vm.addr(user1Privatekey);
    // address user1 = address(1);
    address user2 = address(2);

    function setUp() public{

        drop1 = new AirdropT1(10e18);
        drop2 = new AirdropT2(10e18);

        dropManager = new GuildAirdrop(address(drop1), address(drop2), 1);

        uint256 drop1TotalSupply = drop1.totalSupply();

        drop1.transferAirdropManagement(address(dropManager));
        uint256 mngrBalA1 = drop1.balanceOf(address(dropManager));
        console.log("newbal bal-2",mngrBalA1);
        // drop1.transfer(address(dropManager), drop1TotalSupply);

        // drop1._mint(drop1TotalSupply);
        drop2.transferAirdropManagement(address(dropManager));
        uint256 mngrBalA2 = drop2.balanceOf(address(dropManager));
        console.log("newbal bal-2",mngrBalA2);


        address drop1Owner = drop1.owner();


        deal(user1, 1e10);
        deal(user2, 1e8);

        console.log("user1 eth bal==>",address(user1).balance);
        console.log("user2 eth bal==>",address(user2).balance);

    }

    // function testAirdropClaimWithoutSignature() public {
    //     // vm.prank(user1);
    //     uint256 user1BalBeforeClaim1 = drop1.balanceOf(user1);
        
    //     dropManager.checkEligibility(address(user1));

    //     vm.startPrank(user1);
    //     dropManager.claimAirdrop1();
    //     dropManager.claimAirdrop1();
    //     vm.stopPrank();

    //     uint256 user1BalAfterClaim1 = drop1.balanceOf(user1);
    //     console.log("u1 a1 bal after=>",user1BalAfterClaim1);
    //     console.log("u1 a1 bal before=>",user1BalBeforeClaim1);

    // }

    function testClaimDrop1ToDifferentAddress() public{
        // uint256 drop1Amnt = 1e6;
        address eligibleAcc = user1;
        address claimTo = user2;
        address drop1Addr = address(drop1);
        address drop2Addr = address(drop2);

        bytes32 domainSeperator = dropManager.getDomainSeparator();
// console.log("qualified==>",eligibleAcc);
// console.log("claime to==>",claimTo);

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Sig(address claimToAddress, address qualifiedAddress, address drop1Addr, address drop2Addr)"),
                claimTo,
                eligibleAcc,
                drop1Addr,
                drop2Addr
            )
        );
        uint256 addr2drop1balB4 = drop1.balanceOf(user2);
        uint256 addr2drop2balB4 = drop2.balanceOf(user2);

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeperator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(user1Privatekey, digest);
        console.log("signer=>",vm.addr(user1Privatekey));
        console.log("user-1=>",user1);
         
        vm.startPrank(address(dropManager));
        dropManager.checkEligibility(user1);
        dropManager.claimFirstAirdropToAnotherWallet(GuildAirdrop.Sig(claimTo,eligibleAcc,drop1Addr,drop2Addr), v, r,s);
        dropManager.claimSecondAirdropToAnotherWallet(GuildAirdrop.Sig(claimTo,eligibleAcc,drop1Addr,drop2Addr), v, r,s);
        vm.stopPrank();

        uint256 addr2drop1balAfter = drop1.balanceOf(user2);
        uint256 addr2drop2balAfter = drop2.balanceOf(user2);

        console.log("drop1 claim-to-addr bal b4=>",addr2drop1balB4);
        console.log("drop1 claim-to-addr bal after=>",addr2drop1balAfter);

        console.log("drop2 claim-to-addr bal b4=>",addr2drop2balB4);
        console.log("drop2 claim-to-addr bal after=>",addr2drop2balAfter);
        assertEq(addr2drop1balB4,0);
        assertEq(addr2drop1balAfter,1e9);

        assertEq(addr2drop2balB4,0);
        assertEq(addr2drop2balAfter,1e6);

    }
}
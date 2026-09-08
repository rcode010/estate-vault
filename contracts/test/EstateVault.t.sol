// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {EstateVault} from "../src/EstateVault.sol";

contract EstateVaultTest is Test {
    EstateVault public vault;

    // Create some fake wallet addresses for testing
    address public admin = address(1);
    address public buyer = address(2);

    function setUp() public {
        vm.prank(admin);

        // Deploy a fresh contract: 100 total tokens, 1 Ether per token
        vault = new EstateVault(100, 1 ether, "ipfs://fake-metadata");

        // vm.deal gives our fake buyer 50 Ether so they have money to spend
        vm.deal(buyer, 50 ether);
    }
    function testBuyTokens() public {
        // 1. Pretend to be the buyer for the next transaction
        vm.prank(buyer);

        // 2. The buyer calls buyTokens(2) and attaches 2 Ether to pay for them
        vault.buyTokens{value: 2 ether}(2);

        // 3. Check if the database updated correctly
        assertEq(vault.balances(buyer), 2);
        assertEq(vault.tokensSold(), 2);

        // 4. Check if the smart contract actually received the money
        assertEq(address(vault).balance, 2 ether);
    }
    function testCannotBuyWithNotEnoughMoney() public {
        vm.prank(buyer);

        vm.expectRevert("Not enough Ether sent");

        vault.buyTokens{value: 1 ether}(2);
    }
    function testAdminCanWithdraw() public {
        // 1. Put some money in the contract (Buyer buys 2 tokens for 2 Ether)
        vm.prank(buyer);
        vault.buyTokens{value: 2 ether}(2);

        // Record how much money the admin wallet has before withdrawing
        uint256 adminBalanceBefore = admin.balance;

        // 2. Pretend to be the admin and execute the withdrawal
        vm.prank(admin);
        vault.withdrawFunds();

        // 3. Verify the admin's wallet balance went up by exactly 2 Ether
        assertEq(admin.balance, adminBalanceBefore + 2 ether);

        // 4. Verify the contract's digital safe is now empty
        assertEq(address(vault).balance, 0);
    }

    function testNonAdminCannotWithdraw() public {
        // Pretend to be the buyer (an unauthorized user)
        vm.prank(buyer);

        // Tell Foundry we expect the security check to kick in and block this
        vm.expectRevert("Only admin can withdraw");

        // The buyer attempts to call the admin-only function
        vault.withdrawFunds();
    }
    function testAdminCanDepositRent() public {
        // 1. Give the admin some fake money to use
        vm.deal(admin, 10 ether);

        // 2. Pretend to be the admin
        vm.prank(admin);

        // 3. Admin deposits 5 Ether into the contract as monthly rent
        vault.depositRent{value: 5 ether}();

        // 4. Verify the contract's digital safe received the 5 Ether
        assertEq(address(vault).balance, 5 ether);
    }
    function testTransferTokens() public {
        // 1. Buyer buys 2 tokens
        vm.prank(buyer);
        vault.buyTokens{value: 2 ether}(2);

        // 2. Buyer transfers 1 token to a new wallet (we'll just use address(3))
        address friend = address(3);

        vm.prank(buyer);
        vault.transferTokens(friend, 1);

        // 3. Verify the balances updated correctly
        assertEq(vault.balances(buyer), 1);
        assertEq(vault.balances(friend), 1);
    }
    function testAdminCanSetTokenPrice() public {
        // 1. Pretend to be the admin
        vm.prank(admin);
        
        // 2. Admin changes the price from 1 Ether to 3 Ether
        vault.setTokenPrice(3 ether);
        
        // 3. Verify the contract's state actually updated
        assertEq(vault.tokenPrice(), 3 ether);
    }
}
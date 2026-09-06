// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract EstateVault {
    address public admin;
    uint256 public totalSupply;
    uint256 public tokensSold;
    uint256 public pricePerToken;
    string public propertyMetadataURI;

    mapping(address => uint256) public balances;
    uint256 public totalRentDeposited;
    mapping(address => uint256) public rentClaimed;

    constructor( uint256 _totalSupply, uint256 _pricePerToken, string memory _propertyMetadataURI){
        admin = msg.sender;
        totalSupply = _totalSupply;
        pricePerToken = _pricePerToken;
        propertyMetadataURI = _propertyMetadataURI;
    }

    function  buyTokens(uint256 _amount) public payable{
        uint256 totalCost = _amount * pricePerToken;
        require(msg.value >= totalCost,"Not enough Ether sent");
        require(tokensSold + _amount <= totalSupply,"Not enough tokens left");

        balances[msg.sender] += _amount;
        tokensSold += _amount;

    }
    function withdrawFunds() public {
        require(msg.sender == admin,"Only admin can withdraw");
        payable(admin).transfer(address(this).balance);
    }
    function claimRent() public {
        require(balances[msg.sender] > 0, "You do not own any tokens");

        uint256 totalOwed = (balances[msg.sender] * totalRentDeposited) / tokensSold;

        uint256 amountToPay = totalOwed - rentClaimed[msg.sender];
        require(amountToPay > 0, "No new rent to claim");

        rentClaimed[msg.sender] += amountToPay;

        payable(msg.sender).transfer(amountToPay);
    }

}
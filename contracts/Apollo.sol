// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ApolloToken is ERC20("Apollo Token", "APL"), Ownable {
    uint256 public totalSupplyCap = 500_000_000 * 10 ** 18; // 500 million tokens with 18 decimal places
    uint256 public airdropAmount = 10_000 * 10 ** 18; // Amount to distribute in airdrop
    uint256 public salePrice = 1 ether; // Price per token in wei

    mapping(address => bool) public voters;
    mapping(address => uint256) public votes;

    event Airdrop(address indexed recipient, uint256 amount);
    event Sale(address indexed buyer, uint256 amount);

    constructor() {
        // Mint initial supply to the contract owner
        _mint(msg.sender, totalSupplyCap);
    }

    // Airdrop tokens to multiple recipients
    function distributeAirdrop(address[] memory recipients) external onlyOwner {
        require(recipients.length > 0, "No recipients provided");

        for (uint256 i = 0; i < recipients.length; i++) {
            address recipient = recipients[i];
            require(
                !voters[recipient],
                "Recipient has already received tokens"
            );
            _transfer(msg.sender, recipient, airdropAmount);
            voters[recipient] = true;
            emit Airdrop(recipient, airdropAmount);
        }
    }

    // Buy tokens during the sale
    function buyTokens(uint256 amount) external payable {
        require(msg.value >= amount * salePrice, "Insufficient Ether sent");
        require(
            totalSupply() + amount <= totalSupplyCap,
            "Exceeds total supply cap"
        );

        _transfer(owner(), msg.sender, amount);
        emit Sale(msg.sender, amount);
    }

    // Allow token holders to vote on proposals
    function vote(uint256 proposalId, uint256 amount) external {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        require(voters[msg.sender], "Not eligible to vote");

        // Implement your governance logic here, e.g., record votes for a proposal
        // You may want to use a mapping to store votes and check if a voter has already voted

        votes[msg.sender] = amount;
    }

    // Add more governance functions as needed

    // Transfer ownership of the contract
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }
}

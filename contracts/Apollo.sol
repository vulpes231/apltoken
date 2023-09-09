// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ApolloToken is ERC20("Apollo Token", "APL"), Ownable {
    uint256 public totalSupplyCap = 500_000_000 * 10 ** 18; // 500 million tokens with 18 decimal places
    uint256 public airdropAmount = 10_000 * 10 ** 18; // Amount to distribute in airdrop
    uint256 public salePrice = 1 ether; // Price per token in wei
    uint256 public proposalCounter;
    mapping(address => bool) public voters;
    mapping(address => uint256) public votes;

    // Declare a mapping to store proposals
    mapping(uint256 => Proposal) public proposals;

    // Declare a mapping to store whether an address has already voted on a proposal
    mapping(address => mapping(uint256 => bool)) public hasVoted;

    // Declare an array to store voters
    address[] public voterList;

    event Airdrop(address indexed recipient, uint256 amount);
    event Sale(address indexed buyer, uint256 amount);
    event Voted(address indexed voter, uint256 proposalId, uint256 amount);

    // Define a struct to represent a proposal
    struct Proposal {
        address proposer;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isOpen;
    }

    constructor() {
        // Mint initial supply to the contract owner
        _mint(msg.sender, totalSupplyCap);
        proposalCounter = 0; // Initialize proposal counter
    }

    // Function to create a new proposal
    function createProposal() external onlyOwner {
        proposals[proposalCounter] = Proposal({
            proposer: msg.sender,
            votesFor: 0,
            votesAgainst: 0,
            isOpen: true
        });

        // Initialize the hasVoted mapping for the new proposal
        for (uint256 i = 0; i < proposalCounter; i++) {
            hasVoted[msg.sender][i] = false;
        }

        proposalCounter++;
    }

    // Function to add a voter
    function addVoter(address voter) external onlyOwner {
        require(!voters[voter], "Voter already exists");
        voters[voter] = true;
        voterList.push(voter);
    }

    // Function to remove a voter
    function removeVoter(address voter) external onlyOwner {
        require(voters[voter], "Voter does not exist");
        voters[voter] = false;
        // To keep the voterList compact, we remove the voter by swapping with the last element
        uint256 lastIndex = voterList.length - 1;
        for (uint256 i = 0; i < voterList.length; i++) {
            if (voterList[i] == voter) {
                voterList[i] = voterList[lastIndex];
                voterList.pop();
                break;
            }
        }
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
        require(proposals[proposalId].isOpen, "Proposal is not open");
        require(
            !hasVoted[msg.sender][proposalId],
            "Already voted on this proposal"
        );

        // Update the voter's vote balance
        votes[msg.sender] = amount;

        // Update the proposal's vote count
        if (amount > 0) {
            proposals[proposalId].votesFor += amount;
        } else {
            proposals[proposalId].votesAgainst -= amount;
        }

        // Mark the voter as having voted on this proposal
        hasVoted[msg.sender][proposalId] = true;

        // You may also want to emit an event to log the vote
        emit Voted(msg.sender, proposalId, amount);
    }

    // Add more governance functions as needed

    // Transfer ownership of the contract
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }

    // Pure function to return the total supply of tokens
    function getTotalSupply() external view returns (uint256) {
        return totalSupplyCap;
    }

    // Pure function to return the list of voters
    function getVoters() external view returns (address[] memory) {
        return voterList;
    }

    // Pure function to return a specific proposal
    function getProposal(
        uint256 proposalId
    ) external view returns (address, uint256, uint256, bool) {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.isOpen
        );
    }

    // Pure function to return the number of votes for a specific proposal
    function getVotesForProposal(
        uint256 proposalId
    ) external view returns (uint256) {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        return proposals[proposalId].votesFor;
    }

    // Pure function to return the number of votes against a specific proposal
    function getVotesAgainstProposal(
        uint256 proposalId
    ) external view returns (uint256) {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        return proposals[proposalId].votesAgainst;
    }

    // Pure function to return the number of proposals
    function getProposalCount() external view returns (uint256) {
        return proposalCounter;
    }
}

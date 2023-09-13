// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract ApolloToken is ERC20("Apollo Token", "APL"), Ownable {
    ISwapRouter public immutable swapRouter;
    address public constant APL = 0xe7668e3A8a59Fa2e1Cbfda65b4502DD459276a30;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint24 public constant feeTier = 3000;

    uint256 public totalSupplyCap = 500_000_000 * 10 ** 18; // 500 million tokens with 18 decimal places
    uint256 public airdropAmount = 10_000 * 10 ** 18; // Amount to distribute in airdrop
    uint256 public salePrice = 150000000000000000; // Price per token in wei
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

    // Enum to represent proposal status
    enum ProposalStatus {
        Pending,
        Executed,
        Cancelled
    }

    // Struct to represent a proposal
    struct Proposal {
        address proposer;
        string title;
        address walletAddress;
        string actionType;
        string tokenShortName;
        string proposalDetails;
        uint256 votesFor;
        uint256 votesAgainst;
        bool isOpen;
        uint256 startTime;
        ProposalStatus status;
    }

    constructor(ISwapRouter _swapRouter) {
        // Mint initial supply to the contract owner
        _mint(msg.sender, totalSupplyCap);
        proposalCounter = 0; // Initialize proposal counter
        swapRouter = _swapRouter;
    }

    // Function to create a new proposal
    function createProposal(
        string memory _title,
        address _walletAddress,
        string memory _actionType,
        string memory _tokenShortName,
        string memory _proposalDetails
    ) external {
        require(
            balanceOf(msg.sender) >= (totalSupplyCap * 15) / 10000,
            "Insufficient balance to submit a proposal"
        );

        // Create a new proposal
        proposals[proposalCounter] = Proposal({
            proposer: msg.sender,
            title: _title,
            walletAddress: _walletAddress,
            actionType: _actionType,
            tokenShortName: _tokenShortName,
            proposalDetails: _proposalDetails,
            votesFor: 0,
            votesAgainst: 0,
            isOpen: true,
            startTime: block.timestamp,
            status: ProposalStatus.Pending
        });

        // Initialize the hasVoted mapping for the new proposal
        for (uint256 i = 0; i < voterList.length; i++) {
            hasVoted[voterList[i]][proposalCounter] = false;
        }

        proposalCounter++;
    }

    // Function to vote on a proposal
    function voteOnProposal(uint256 proposalId, uint256 amount) external {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        require(proposals[proposalId].isOpen, "Proposal is not open");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
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

    // Function to check the status of a proposal and execute/cancel it if applicable
    function checkProposalStatus(uint256 proposalId) external onlyOwner {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        require(
            proposals[proposalId].status == ProposalStatus.Pending,
            "Proposal status is not pending"
        );

        if (block.timestamp >= proposals[proposalId].startTime + 7 days) {
            // Proposal voting period has ended
            if (
                proposals[proposalId].votesFor >
                proposals[proposalId].votesAgainst
            ) {
                // Execute the proposal
                // Implement your logic here for executing the proposal
                // For example, transferring tokens or performing actions
                proposals[proposalId].status = ProposalStatus.Executed;
            } else {
                // Cancel the proposal
                proposals[proposalId].status = ProposalStatus.Cancelled;
            }
        }
    }

    // Additional functions to get proposal details
    function getProposalDetails(
        uint256 proposalId
    )
        external
        view
        returns (
            address,
            string memory,
            address,
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            bool,
            uint256,
            ProposalStatus
        )
    {
        require(proposalId < proposalCounter, "Invalid proposal ID");
        Proposal memory proposal = proposals[proposalId];
        return (
            proposal.proposer,
            proposal.title,
            proposal.walletAddress,
            proposal.actionType,
            proposal.tokenShortName,
            proposal.proposalDetails,
            proposal.votesFor,
            proposal.votesAgainst,
            proposal.isOpen,
            proposal.startTime,
            proposal.status
        );
    }

    // Function to swap DAO tokens for ETH using Uniswap V3
    function swapWETHForDAI(
        uint256 amountIn
    ) external returns (uint256 amountOut) {
        // Transfer the specified amount of WETH9 to this contract.
        TransferHelper.safeTransferFrom(
            WETH9,
            msg.sender,
            address(this),
            amountIn
        );
        // Approve the router to spend WETH9.
        TransferHelper.safeApprove(WETH9, address(swapRouter), amountIn);
        // Note: To use this example, you should explicitly set slippage limits, omitting for simplicity
        uint256 minOut = /* Calculate min output */ 0;
        uint160 priceLimit = /* Calculate price limit */ 0;
        // Create the params that will be used to execute the swap
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: WETH9,
                tokenOut: APL,
                fee: feeTier,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: minOut,
                sqrtPriceLimitX96: priceLimit
            });
        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
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
        require(totalSupply() >= amount, "Exceeds total token supply");
        require(amount > 0, "Amount must be greater than zero");

        // Calculate the cost in Ether
        uint256 cost = amount * salePrice;
        require(msg.value >= cost, "Insufficient Ether sent");

        // Transfer tokens to the buyer
        _transfer(owner(), msg.sender, amount);

        // Decrease the total supply
        totalSupplyCap -= amount;

        // Emit the Sale event
        emit Sale(msg.sender, amount);

        // Refund excess Ether back to the buyer
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
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

    // Pure function to get all proposal details
    function getAllProposals() external view returns (Proposal[] memory) {
        Proposal[] memory allProposals = new Proposal[](proposalCounter);
        for (uint256 i = 0; i < proposalCounter; i++) {
            allProposals[i] = proposals[i];
        }
        return allProposals;
    }
}

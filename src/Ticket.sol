// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// view & pure functions

// [ ] You should create NFT contract that represents a ticket.
// [ ] A ticket should have simple metadata on-chain data. - URIStorage
// [ ]      Bonus * Additional data can be stored off-chain. - URIStorage
// [ ] Users should be able to buy tickets. - Purchase tickets
// [ ] Starting from a particular block people can buy tickets for limited time.
// [ ] Funds from purchases should be stored in the contract.
// [ ] Only the contract itself can use these funds.
// [ ] After purchase time ends a random winner should be selected. You can complete simple random generation.
// [ ] A function for a surprise winner should be created which will award the random generated winner with 50% of the gathered funds.

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC721URIStorageUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {TicketInterface} from "./interfaces/TicketInterface.i.sol";

error Ticket__InvalidParameters();
error Ticket__InvalidPurchasingPrice();
error Ticket__LotteryNotOpen();

/**
 * @title NFT Lottery
 * @author Todor Gospodinov
 * @notice Upgreadable ERC721 contract for lottery ticket
 * @notice Allows users to buy tickets for a lottery for a certain period of time, and then randomly select a winner
 *
 */
contract Ticket is TicketInterface, ERC721URIStorageUpgradeable {
    LotteryState public lotteryState;
    uint256 public START_TIMESTAMP;
    uint256 public END_TIMESTAMP;

    uint128 public TICKET_PRICE;
    uint256 public s_tokenId = 0;

    /**
     * @notice Initializer function which acts as constructor for upgradeable contracts.
     * @param name_  The name of the token.
     * @param symbol_  The symbol used to display the token.
     * @param _startTimestamp  The timestamp when the lottery starts.
     * @param _endTimestamp  The timestamp when the lottery ends.
     * @param _ticketPrice  The price of a ticket.
     */
    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint128 _ticketPrice
    ) external override initializer {
        if (
            bytes(name_).length == 0 || bytes(symbol_).length == 0 || _startTimestamp < block.timestamp
                || _endTimestamp <= _startTimestamp || _ticketPrice <= 0
        ) {
            revert Ticket__InvalidParameters();
        }

        START_TIMESTAMP = _startTimestamp;
        END_TIMESTAMP = _endTimestamp;
        TICKET_PRICE = _ticketPrice;

        __ERC721_init(name_, symbol_);
    }

    modifier updateLotteryState() {
        if (block.timestamp >= START_TIMESTAMP && block.timestamp <= END_TIMESTAMP) {
            lotteryState = LotteryState.OPEN;
        } else {
            lotteryState = LotteryState.CLOSED;
        }
        _;
    }

    modifier onlyWhenLotteryIsOpen() {
        if (lotteryState != LotteryState.OPEN) {
            revert Ticket__LotteryNotOpen();
        }
        _;
    }

    // Users should be able to buy tickets only when the lottery is OPEN
    function buyTicket() external payable override onlyWhenLotteryIsOpen {
        if (msg.value != TICKET_PRICE) {
            revert Ticket__InvalidPurchasingPrice();
        }
        _purchaseTicket("");
    }

    function buyTicketWithURI(string calldata tokenURI_) external payable override onlyWhenLotteryIsOpen {
        if (msg.value != TICKET_PRICE) {
            revert Ticket__InvalidPurchasingPrice();
        }
        _purchaseTicket(tokenURI_);
    }

    /**
     * @notice Internal function to purchase a ticket with an optional tokenURI.
     * @param tokenURI_  [OPTIONAL] The URI of the user's ticket pointing to and off-chain resource.
     */
    function _purchaseTicket(string memory tokenURI_) private {
        if (bytes(tokenURI_).length > 0) {
            _setTokenURI(s_tokenId, tokenURI_);
        }
        _safeMint(msg.sender, s_tokenId);
        s_tokenId++;
    }

    /**
     * @notice
     */
    function pickWinner() external override {}

    // function draftSmallPrizeWinner() external override {}

    // function draftGrandPrizeWinner() external override {}

    // function paySmallReward() external override {}

    // function payGrandReward() external override {}
}

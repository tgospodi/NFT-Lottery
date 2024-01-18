// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC721URIStorageUpgradeable} from
    "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {TicketInterface} from "./interfaces/TicketInterface.i.sol";
import {Draft} from "./Draft.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFT Lottery
 * @author Todor Gospodinov
 * @notice Upgreadable ERC721 contract for lottery ticket
 * @notice Allows users to buy tickets for a lottery for a certain period of time, and then randomly selects a winner
 *
 */
contract Ticket is TicketInterface, ERC721URIStorageUpgradeable, ReentrancyGuard {
    error Ticket__InvalidParameters();
    error Ticket__InvalidPurchasingPrice();
    error Ticket__LotteryNotOpen();
    error Ticket__NotEnoughTimePassed();
    error Ticket__WinnerAlreadyPicked();
    error Ticket__Unauthorized();
    error Ticket__WinnerAlreadyPaid();
    error Ticket__TransactionFailed();

    Draft public DRAFT;
    LotteryState public lotteryState;
    uint256 public START_TIMESTAMP;
    uint256 public END_TIMESTAMP;

    uint128 public TICKET_PRICE;
    uint256 public s_tokenId = 0;

    uint256 public smallWinnerTicketId;
    uint256 public smallWinnerRewardAmount;
    uint256 public grandWinnerTicketId;

    bool smallWinnerPicked;
    bool grandWinnerPicked;
    bool smallPrizePaid;
    bool grandPrizePaid;

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
        uint128 _ticketPrice,
        address _draftAddress
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
        DRAFT = Draft(_draftAddress);

        __ERC721_init(name_, symbol_);
    }

    event SmallPrizeWinnerDrafted(address indexed winner, uint256 indexed reward);

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
     * @notice Function to pick a winner for the lottery.
     * @notice Defines the winner type (grand winner or small prize winner) based on the time passed.
     */
    function pickWinner() external override {
        // the first winner should be picked after half of the lottery time has passed
        if (block.timestamp < (END_TIMESTAMP - START_TIMESTAMP) / 2) {
            revert Ticket__NotEnoughTimePassed();
        }
        if (
            (block.timestamp < END_TIMESTAMP && smallWinnerPicked)
                || (block.timestamp >= END_TIMESTAMP && grandWinnerPicked)
        ) {
            revert Ticket__WinnerAlreadyPicked();
        }

        // if the lottery is still open, pick a small prize winner
        // else pick a grand prize winner
        if (block.timestamp < END_TIMESTAMP) {
            DRAFT.getRandomNumber("draftSmallPrizeWinner(uint256)");
            smallWinnerPicked = true;
        } else {
            DRAFT.getRandomNumber("draftGrandPrizeWinner(uint256)");
            grandWinnerPicked = true;
        }
    }

    /**
     * @notice Drafts the small prize winner and store it.
     * @notice The small prize winner should receive 50% of the gathered funds.
     * @dev The draftSmallPrizeWinner function should revert if called from any contract other than the Draft contract.
     * @dev The draftSmallPrizeWinner function should revert if the smallWinnerPicked variable is true.
     * @param randomness The random number generated by the VRF and passed by the callback function.
     */
    function draftSmallPrizeWinner(uint256 randomness) external override {
        if (msg.sender != address(DRAFT)) {
            revert Ticket__Unauthorized();
        }
        if (smallWinnerPicked) {
            revert Ticket__WinnerAlreadyPicked();
        }

        // using modulo division to get a random tokenId
        smallWinnerTicketId = randomness % s_tokenId;
        smallWinnerRewardAmount = address(this).balance / 2;
        smallWinnerPicked = true;
        emit SmallPrizeWinnerDrafted(ownerOf(smallWinnerTicketId), smallWinnerRewardAmount);
    }

    function draftGrandPrizeWinner(uint256 randomness) external override {
        if (msg.sender != address(DRAFT)) {
            revert Ticket__Unauthorized();
        }
        if (grandWinnerPicked) {
            revert Ticket__WinnerAlreadyPicked();
        }

        // using modulo division to get a random tokenId
        grandWinnerTicketId = randomness % s_tokenId;
        grandWinnerPicked = true;
    }

    // Transfer half the funds to the small lottery winner
    function paySmallReward() external override nonReentrant {
        address winner = ownerOf(smallWinnerTicketId);

        if (msg.sender != winner) {
            revert Ticket__Unauthorized();
        }
        if (smallPrizePaid) {
            revert Ticket__WinnerAlreadyPaid();
        }

        smallPrizePaid = true;

        (bool success,) = winner.call{value: smallWinnerRewardAmount}("");
        if (!success) {
            revert Ticket__TransactionFailed();
        }
    }

    function payGrandReward() external override nonReentrant {
        address winner = ownerOf(grandWinnerTicketId);

        if (msg.sender != winner) {
            revert Ticket__Unauthorized();
        }
        if (grandPrizePaid) {
            revert Ticket__WinnerAlreadyPaid();
        }

        uint256 grandRewardAmount;
        if (smallPrizePaid) {
            grandRewardAmount = address(this).balance;
        } else {
            grandRewardAmount = address(this).balance - smallWinnerRewardAmount;
        }

        grandPrizePaid = true;

        (bool success,) = winner.call{value: grandRewardAmount}("");
        if (!success) {
            revert Ticket__TransactionFailed();
        }
    }

    function saleOpen() external view override returns (bool) {
        return lotteryState == LotteryState.OPEN;
    }

    function saleClosed() external view override returns (bool) {
        return lotteryState == LotteryState.CLOSED;
    }

    function startTimestamp() external view returns (uint256) {
        return START_TIMESTAMP;
    }

    function endTimestamp() external view returns (uint256) {
        return END_TIMESTAMP;
    }

    function ticketPrice() external view returns (uint128) {
        return TICKET_PRICE;
    }

    function draftAddress() external view returns (address) {
        return address(DRAFT);
    }
}

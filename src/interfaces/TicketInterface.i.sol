// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface TicketInterface {
    enum RaffleState {
        OPEN, // converted to 0?
        CLOSED // converted to 1?
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint128 _ticketPrice
    ) external;

    function buyTicket() external payable;
    function buyTicketWithURI(string calldata tokenURI_) external payable;

    // function pickWinner() external;
    // function draftSmallPrizeWinner() external;
    // function draftGrandPrizeWinner() external;

    // function paySmallReward() external;
    // function payGrandReward() external;
}

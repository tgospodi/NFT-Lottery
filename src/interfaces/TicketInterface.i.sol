// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface TicketInterface {
    enum LotteryState {
        OPEN, // converted to 0?
        CLOSED // converted to 1?
    }

    function initialize(
        string calldata name_,
        string calldata symbol_,
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint128 _ticketPrice,
        address _draftAddress
    ) external;

    function buyTicket() external payable;
    function buyTicketWithURI(string calldata tokenURI_) external payable;

    function pickWinner() external;
    function draftSmallPrizeWinner(uint256) external;
    function draftGrandPrizeWinner(uint256) external;

    function paySmallReward() external;
    function payGrandReward() external;

    function saleOpen() external view returns (bool);
    function saleClosed() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {Ticket} from "../src/Ticket.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Vm} from "../lib/forge-std/src/Vm.sol";

contract TicketTest is Test {
    Ticket ticket;

    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() public {
        ticket = new Ticket();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    // -----------------------------------------
    // -------------- TESTS --------------------
    // -----------------------------------------

    /**
     * @notice Tests the initialize function
     * @notice Should revert if parameter 0 is provided
     */
    function testInitialize() public {
        vm.expectRevert(Ticket.Ticket__InvalidParameters.selector);
        ticket.initialize("test", "TST", 0, 0, 0, address(0));
    }

    function testBuyTicket() public {
        uint128 fee = 12 ether;
        uint256 startTime = block.timestamp;
        uint256 endTime = startTime + 1 days;
        ticket.initialize("test", "TST", startTime, endTime, fee, address(this));
        vm.expectRevert(Ticket.Ticket__InvalidPurchasingPrice.selector);
        ticket.buyTicket{value: 1 ether}();
    }
}
